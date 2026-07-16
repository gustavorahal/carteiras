require "test_helper"

class TransferenciasECorporativosTest < ActiveSupport::TestCase
  test "transferência de caixa gera lançamentos opostos e saldo líquido zero" do
    outra_conta = ContaInvestimento.create!(carteira: @carteira, corretora: @corretora, nome: "Conta 2")
    outro_caixa = ContaCaixa.create!(conta_investimento: outra_conta, moeda: @brl)
    evento = RegistrarTransferenciaCaixa.call(carteira: @carteira, usuario: @usuario,
      atributos: { conta_caixa_origem: @caixa_brl, conta_caixa_destino: outro_caixa,
        valor: 50, data_efetiva: Date.new(2026, 2, 1) }, data_competencia: Date.new(2026, 2, 1))
    assert_equal 2, evento.lancamentos_caixa.count
    assert_equal 0.to_d, evento.lancamentos_caixa.sum(:valor)
  end

  test "transferência de custódia move quantidade e custo sem realizar resultado" do
    destino = ContaInvestimento.create!(carteira: @carteira, corretora: @corretora, nome: "Conta 2")
    registrar_operacao(natureza: :compra, quantidade: 10, preco: 20)
    RegistrarTransferenciaCustodia.call(carteira: @carteira, usuario: @usuario,
      atributos: { conta_origem: @conta, conta_destino: destino, ativo: @ativo, quantidade: 4 },
      data_competencia: Date.new(2026, 2, 1))
    origem = PosicaoAtual.find_by!(conta_investimento: @conta, ativo: @ativo)
    recebida = PosicaoAtual.find_by!(conta_investimento: destino, ativo: @ativo)
    assert_equal [6.to_d, 120.to_d, 0.to_d], [origem.quantidade, origem.custo_total, origem.resultado_realizado]
    assert_equal [4.to_d, 80.to_d, 0.to_d], [recebida.quantidade, recebida.custo_total, recebida.resultado_realizado]
  end

  test "desdobramento preserva custo total" do
    registrar_operacao(natureza: :compra, quantidade: 10, preco: 20)
    RegistrarEventoCorporativo.call(carteira: @carteira, usuario: @usuario,
      atributos: { tipo: :desdobramento, conta_investimento: @conta, ativo_origem: @ativo,
        fator: 2, regra_alocacao_custo: :preservar }, data_competencia: Date.new(2026, 2, 1))
    posicao = PosicaoAtual.find_by!(conta_investimento: @conta, ativo: @ativo)
    assert_equal 20.to_d, posicao.quantidade
    assert_equal 200.to_d, posicao.custo_total
  end

  test "grupamento aceita quantidade final e incorporação rejeita o mesmo ativo" do
    registrar_operacao(natureza: :compra, quantidade: 10, preco: 20)
    RegistrarEventoCorporativo.call(carteira: @carteira, usuario: @usuario,
      atributos: { tipo: :grupamento, conta_investimento: @conta, ativo_origem: @ativo,
        quantidade_final: 3, regra_alocacao_custo: :preservar },
      data_competencia: Date.new(2026, 2, 1))
    assert_equal 3.to_d, PosicaoAtual.find_by!(conta_investimento: @conta, ativo: @ativo).quantidade

    assert_raises(ActiveRecord::RecordInvalid) do
      RegistrarEventoCorporativo.call(carteira: @carteira, usuario: @usuario,
        atributos: { tipo: :incorporacao, conta_investimento: @conta, ativo_origem: @ativo,
          ativo_destino: @ativo, quantidade_final: 2, regra_alocacao_custo: :preservar },
        data_competencia: Date.new(2026, 3, 1))
    end
  end

  test "incorporação realiza fração com alocação explícita de custo" do
    destino = Ativo.create!(codigo: "NOVO3", mercado: "B3", tipo: :acao,
      moeda_negociacao: @brl, moeda_exposicao: @brl)
    registrar_operacao(natureza: :compra, quantidade: 10, preco: 20)
    RegistrarEventoCorporativo.call(carteira: @carteira, usuario: @usuario,
      atributos: { tipo: :incorporacao, conta_investimento: @conta, ativo_origem: @ativo,
        ativo_destino: destino, quantidade_final: 5, valor_fracao: 30, moeda: @brl,
        taxa_conversao_base: 1, percentual_custo_fracao: 10,
        regra_alocacao_custo: :realizar_fracao }, data_competencia: Date.new(2026, 2, 1))
    posicao = PosicaoAtual.find_by!(conta_investimento: @conta, ativo: destino)
    assert_equal 5.to_d, posicao.quantidade
    assert_equal 180.to_d, posicao.custo_total
    assert_equal 10.to_d, posicao.resultado_realizado
    assert_equal 30.to_d, ConsultarSaldosCaixa.call(carteira: @carteira).fetch(@caixa_brl.id) + 200
  end

  test "registro rejeita conta de outra carteira antes de criar rascunho" do
    outra_carteira = Carteira.create!(investidor: @investidor, nome: "Outra", moeda_base: @brl)
    outra_conta = ContaInvestimento.create!(carteira: outra_carteira, corretora: @corretora, nome: "Externa")
    assert_no_difference -> { EventoFinanceiro.count } do
      assert_raises(ActiveRecord::RecordInvalid) do
        RegistrarOperacao.call(carteira: @carteira, usuario: @usuario,
          atributos: atributos_operacao(natureza: :compra, quantidade: 1, preco: 10, conta: outra_conta),
          confirmar: false)
      end
    end
  end
end
