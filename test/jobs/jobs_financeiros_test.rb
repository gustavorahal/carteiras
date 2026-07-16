require "test_helper"

class JobsFinanceirosTest < ActiveSupport::TestCase
  teardown { BuscadoresCotacao.limpar }

  test "job de cotações resolve buscadores registrados no processo" do
    fonte = FonteCotacao.create!(nome: "Teste", prioridade: 1, tipos_atendidos: ["ativo"])
    BuscadoresCotacao.registrar(fonte.nome, ->(_ativo, _data) { 12.34.to_d })
    BuscarCotacoesFechamentoJob.perform_now(data: Date.new(2026, 1, 10))

    assert_equal 12.34.to_d, CotacaoAtivo.find_by!(ativo: @ativo,
      data: Date.new(2026, 1, 10)).preco
  end

  test "job de importação retoma itens normalizados e atualiza contadores" do
    importacao = ImportacaoExtrato.create!(conta_caixa: @caixa_brl, corretora: @corretora,
      nome_original: "x.csv", checksum_sha256: "z" * 64, formato: "avenue", total_itens: 1,
      itens_pendentes: 1)
    importacao.itens.create!(ordem: 1, data_movimentacao: Date.current,
      data_liquidacao: Date.current, descricao: "Depósito", valor: 100, moeda: @brl,
      chave_deduplicacao: "item")
    ProcessarItensImportacaoJob.perform_now(importacao, @usuario)

    assert importacao.reload.concluida?
    assert_equal 1, importacao.itens_processados
    assert_equal 0, importacao.itens_pendentes
    assert importacao.itens.first.evento_criado?
  end
end
