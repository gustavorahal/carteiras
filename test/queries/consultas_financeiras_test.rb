require "test_helper"

class ConsultasFinanceirasTest < ActiveSupport::TestCase
  test "replay completo reproduz posições atuais" do
    registrar_operacao(natureza: :compra, quantidade: 10, preco: 20)
    registrar_operacao(natureza: :venda, quantidade: 3, preco: 25, data: Date.new(2026, 2, 1))
    atual = PosicaoAtual.find_by!(conta_investimento: @conta, ativo: @ativo)
    historico = ConsultarPosicaoHistorica.call(carteira: @carteira, data: Date.current)
      .fetch([@conta.id, @ativo.id])
    assert_equal atual.quantidade, historico[:quantidade]
    assert_equal atual.custo_total, historico[:custo_total]
    assert_equal atual.resultado_realizado, historico[:resultado_realizado]
  end

  test "posição atual mantém número constante de consultas para 2 e 50 ativos" do
    fonte = FonteCotacao.create!(nome: "Manual", prioridade: 0, tipos_atendidos: ["ativo"])
    50.times do |i|
      ativo = Ativo.create!(codigo: "AT#{i.to_s.rjust(3, "0")}", mercado: "B3", tipo: :acao,
        moeda_negociacao: @brl, moeda_exposicao: @brl)
      PosicaoAtual.create!(conta_investimento: @conta, ativo:, quantidade: 1, custo_total: 10,
        custo_total_base: 10, resultado_realizado: 0)
      CotacaoAtivo.create!(ativo:, data: Date.current, preco: 11, moeda: @brl, fonte_cotacao: fonte)
    end

    cinquenta = contar_consultas { ConsultarPosicaoCarteira.call(carteira: @carteira) }
    PosicaoAtual.where.not(ativo_id: PosicaoAtual.limit(2).select(:ativo_id)).delete_all
    duas = contar_consultas { ConsultarPosicaoCarteira.call(carteira: @carteira) }
    assert_operator cinquenta, :<=, 5
    assert_equal cinquenta, duas
  end

  test "saldo de todas as contas é calculado em uma agregação" do
    RegistrarMovimentacaoCaixa.call(carteira: @carteira, usuario: @usuario,
      atributos: { conta_caixa: @caixa_brl, natureza: :aporte, direcao: :entrada,
        valor: 100, data_efetiva: Date.current })
    consultas = contar_consultas { assert_equal 100.to_d, ConsultarSaldosCaixa.call(carteira: @carteira).fetch(@caixa_brl.id) }
    assert_equal 1, consultas
  end

  test "posição multimoeda informa defasagem da cotação e do câmbio" do
    ativo = Ativo.create!(codigo: "AAPL", mercado: "NASDAQ", tipo: :acao,
      moeda_negociacao: @usd, moeda_exposicao: @usd)
    PosicaoAtual.create!(conta_investimento: @conta, ativo:, quantidade: 1,
      custo_total: 100, custo_total_base: 500, resultado_realizado: 0)
    fonte = FonteCotacao.create!(nome: "Manual", prioridade: 0, tipos_atendidos: %w[ativo cambio])
    ontem = Date.current - 1
    CotacaoAtivo.create!(ativo:, data: ontem, preco: 110, moeda: @usd, fonte_cotacao: fonte)
    CotacaoCambio.create!(moeda_origem: @usd, moeda_destino: @brl, data: ontem,
      taxa: 5, fonte_cotacao: fonte)

    item = ConsultarPosicaoCarteira.call(carteira: @carteira).itens.first
    assert item.cotacao_defasada
    assert item.cambio_defasado
    assert_equal ontem, item.data_cambio
    assert_equal 550.to_d, item.valor_base
  end

  private

  def contar_consultas
    total = 0
    callback = lambda do |_nome, _inicio, _fim, _id, payload|
      sql = payload[:sql]
      total += 1 if payload[:name] != "SCHEMA" && sql.match?(/\ASELECT/i) && !sql.include?("pg_attribute")
    end
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { yield }
    total
  end
end
