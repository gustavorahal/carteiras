require "test_helper"

class HistoricoERentabilidadeTest < ActiveSupport::TestCase
  test "evento retroativo reconstrói a carteira inteira na ordem econômica" do
    registrar_operacao(natureza: :compra, quantidade: 2, preco: 20, data: Date.new(2026, 1, 20))
    registrar_operacao(natureza: :compra, quantidade: 1, preco: 10, data: Date.new(2026, 1, 10))
    posicao = PosicaoAtual.find_by!(conta_investimento: @conta, ativo: @ativo)
    assert_equal 3.to_d, posicao.quantidade
    assert_equal 50.to_d, posicao.custo_total
    assert_equal [Date.new(2026, 1, 10), Date.new(2026, 1, 20)],
      @carteira.eventos_financeiros.confirmado.ordenados_para_replay.pluck(:data_competencia)
  end

  test "replay usa taxa gravada no evento mesmo após nova cotação de câmbio" do
    ativo_usd = Ativo.create!(codigo: "AAPL", mercado: "NASDAQ", tipo: :acao,
      moeda_negociacao: @usd, moeda_exposicao: @usd)
    ContaCaixa.create!(conta_investimento: @conta, moeda: @usd)
    atributos = atributos_operacao(natureza: :compra, quantidade: 1, preco: 100, ativo: ativo_usd)
      .merge(taxa_conversao_base: 5, taxa_conversao_fiscal: 5)
    RegistrarOperacao.call(carteira: @carteira, usuario: @usuario, atributos:)
    fonte = FonteCotacao.create!(nome: "Manual", prioridade: 0, tipos_atendidos: ["cambio"])
    CotacaoCambio.create!(moeda_origem: @usd, moeda_destino: @brl, data: Date.current,
      taxa: 6, fonte_cotacao: fonte)
    replay = ConsultarPosicaoHistorica.call(carteira: @carteira, data: Date.current)
    assert_equal 500.to_d, replay.fetch([@conta.id, ativo_usd.id])[:custo_total_base]
  end

  test "TWR diário trata fluxo externo no fim do dia e encadeia o retorno" do
    dia1 = Date.new(2026, 1, 10)
    dia2 = dia1 + 1
    RegistrarMovimentacaoCaixa.call(carteira: @carteira, usuario: @usuario,
      atributos: { conta_caixa: @caixa_brl, natureza: :aporte, direcao: :entrada,
        valor: 100, data_efetiva: dia1 }, data_competencia: dia1)
    atributos = atributos_operacao(natureza: :compra, quantidade: 1, preco: 100, data: dia1)
      .merge(data_liquidacao: dia1)
    RegistrarOperacao.call(carteira: @carteira, usuario: @usuario, atributos:)
    fonte = FonteCotacao.create!(nome: "Manual", prioridade: 0, tipos_atendidos: ["ativo"])
    CotacaoAtivo.create!(ativo: @ativo, data: dia1, preco: 100, moeda: @brl, fonte_cotacao: fonte)
    CotacaoAtivo.create!(ativo: @ativo, data: dia2, preco: 110, moeda: @brl, fonte_cotacao: fonte)

    RecalcularResumosDiarios.call(carteira: @carteira, inicio: dia1, fim: dia2)
    primeiro, segundo = @carteira.resumos_diarios.order(:data).to_a
    assert primeiro.sem_patrimonio_inicial?
    assert segundo.completo?
    assert_equal 0.1.to_d, segundo.twr_diario
    assert_equal 0.1.to_d, ConsultarRentabilidade.call(carteira: @carteira, inicio: dia1, fim: dia2)[:retorno]
  end

  test "evento retroativo invalida resumos existentes e agenda recálculo" do
    dia = Date.new(2026, 1, 10)
    @carteira.resumos_diarios.create!(data: dia, patrimonio_inicial: 100,
      patrimonio_final: 100, valor_ativos: 0, valor_caixa: 100,
      fluxo_externo_liquido: 0, resultado_diario: 0, twr_diario: 0,
      estado_completude: :completo)

    assert_enqueued_with(job: RecalcularResumosDiariosJob) do
      RegistrarMovimentacaoCaixa.call(carteira: @carteira, usuario: @usuario,
        atributos: { conta_caixa: @caixa_brl, natureza: :aporte, direcao: :entrada,
          valor: 10, data_efetiva: dia }, data_competencia: dia)
    end
    assert_equal 0, @carteira.resumos_diarios.count
  end
end
