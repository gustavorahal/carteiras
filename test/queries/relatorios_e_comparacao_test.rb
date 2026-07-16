require "test_helper"

class RelatoriosEComparacaoTest < ActiveSupport::TestCase
  test "comparação histórica usa replay da data e não posição atual" do
    registrar_operacao(natureza: :compra, quantidade: 1, preco: 10,
      data: Date.new(2026, 1, 10))
    registrar_operacao(natureza: :compra, quantidade: 1, preco: 20,
      data: Date.new(2026, 7, 10))
    fonte = FonteCotacao.create!(nome: "Manual", prioridade: 0, tipos_atendidos: ["ativo"])
    CotacaoAtivo.create!(ativo: @ativo, data: Date.new(2026, 3, 1), preco: 15,
      moeda: @brl, fonte_cotacao: fonte)
    referencia = Referencia.create!(nome: "Ações")
    versao = referencia.versoes.create!(vigencia_inicial: Date.new(2026, 1, 1))
    versao.alocacoes.create!(ativo: @ativo, categoria: "Ações", percentual: 100)
    PublicarVersaoReferencia.call(versao)

    comparacao = ConsultarComparacaoReferencia.call(carteira: @carteira,
      referencia:, data: Date.new(2026, 3, 1))
    assert comparacao[:completa]
    assert_equal 1.to_d, comparacao[:posicao].first[:quantidade]
    assert_equal 100.to_d, comparacao[:comparacoes].first[:percentual_atual]
  end

  test "relatório preserva resultado econômico sem se declarar apuração tributária" do
    registrar_operacao(natureza: :compra, quantidade: 1, preco: 10,
      data: Date.new(2026, 1, 10))
    registrar_operacao(natureza: :venda, quantidade: 1, preco: 15,
      data: Date.new(2026, 2, 10))
    relatorio = ConsultarResultadosEconomicos.call(carteira: @carteira, ano: 2026)

    assert_equal 5.to_d, relatorio[:total_resultado]
    assert_equal "acao / BRL", relatorio[:linhas].first.categoria
    assert_includes relatorio[:aviso], "não é apuração tributária"
  end
end
