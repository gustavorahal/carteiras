require "test_helper"
require "tempfile"

class ImportacaoEConciliacaoTest < ActiveSupport::TestCase
  test "normaliza Avenue sem armazenar arquivo e reimportação é idempotente" do
    arquivo = Tempfile.new(["avenue", ".csv"])
    arquivo.write("Data;Hora;Liquidação;Descrição;Valor (U$);Saldo da conta\n")
    arquivo.write("2026-01-10;10:00;2026-01-10;Depósito;US$ 100,00;US$ 100,00\n")
    arquivo.flush

    primeira = NormalizarImportacaoExtrato.call(conta_caixa: @caixa_brl, arquivo:, formato: :avenue)
    segunda = NormalizarImportacaoExtrato.call(conta_caixa: @caixa_brl, arquivo:, formato: :avenue)
    assert_equal primeira, segunda
    assert_equal 1, primeira.itens.count
    assert_not primeira.attributes.key?("arquivo")
    assert_equal 100.to_d, primeira.itens.first.saldo_informado
    assert_equal 0, LancamentoCaixa.count
  ensure
    arquivo&.close!
  end

  test "concilia lançamento esperado sem duplicar saldo" do
    evento = RegistrarMovimentacaoCaixa.call(carteira: @carteira, usuario: @usuario,
      atributos: { conta_caixa: @caixa_brl, natureza: :aporte, direcao: :entrada,
        valor: 100, data_efetiva: Date.new(2026, 1, 10) })
    importacao = ImportacaoExtrato.create!(conta_caixa: @caixa_brl, corretora: @corretora,
      nome_original: "x.csv", checksum_sha256: "a" * 64, formato: "avenue")
    item = importacao.itens.create!(ordem: 1, data_movimentacao: Date.new(2026, 1, 10),
      data_liquidacao: Date.new(2026, 1, 10), descricao: "Depósito", valor: 100, moeda: @brl,
      chave_deduplicacao: "b" * 64)
    assert_no_difference -> { LancamentoCaixa.count } do
      ConciliarItemExtrato.call(item:, usuario: @usuario)
    end
    assert_equal evento.lancamentos_caixa.first, item.reload.lancamento_caixa
    assert item.conciliado?
  end

  test "linhas semelhantes legítimas não são bloqueadas pela deduplicação" do
    importacao = ImportacaoExtrato.create!(conta_caixa: @caixa_brl, corretora: @corretora,
      nome_original: "x.csv", checksum_sha256: "c" * 64, formato: "avenue")
    atributos = { data_movimentacao: Date.current, data_liquidacao: Date.current,
      descricao: "Mesmo texto", valor: 10, moeda: @brl, chave_deduplicacao: "igual" }
    importacao.itens.create!(atributos.merge(ordem: 1))
    assert importacao.itens.create!(atributos.merge(ordem: 2)).persisted?
  end

  test "item ambíguo pode ser resolvido vinculando um lançamento explícito" do
    primeiro = RegistrarMovimentacaoCaixa.call(carteira: @carteira, usuario: @usuario,
      atributos: { conta_caixa: @caixa_brl, natureza: :ajuste, direcao: :entrada,
        valor: 10, data_efetiva: Date.new(2026, 1, 10) })
    RegistrarMovimentacaoCaixa.call(carteira: @carteira, usuario: @usuario,
      atributos: { conta_caixa: @caixa_brl, natureza: :ajuste, direcao: :entrada,
        valor: 10, data_efetiva: Date.new(2026, 1, 11) })
    importacao = ImportacaoExtrato.create!(conta_caixa: @caixa_brl, corretora: @corretora,
      nome_original: "x.csv", checksum_sha256: "d" * 64, formato: "avenue")
    item = importacao.itens.create!(ordem: 1, data_movimentacao: Date.new(2026, 1, 10),
      data_liquidacao: Date.new(2026, 1, 10), descricao: "Ajuste", valor: 10, moeda: @brl,
      chave_deduplicacao: "ambiguo")

    ConciliarItemExtrato.call(item:, usuario: @usuario)
    assert item.reload.ambiguo?
    ConciliarItemExtrato.resolver(item:, usuario: @usuario, decisao: :vincular,
      lancamento: primeiro.lancamentos_caixa.first)
    assert item.reload.conciliado?
    assert_equal primeiro.lancamentos_caixa.first, item.lancamento_caixa
  end
end
