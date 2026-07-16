require "test_helper"

class ProjecaoFinanceiraTest < ActiveSupport::TestCase
  test "compra, venda parcial e zeragem calculam custo médio e resultado" do
    compra = registrar_operacao(natureza: :compra, quantidade: 10, preco: 100, custos: 10)
    posicao = PosicaoAtual.find_by!(conta_investimento: @conta, ativo: @ativo)
    assert_equal 10.to_d, posicao.quantidade
    assert_equal 1_010.to_d, posicao.custo_total
    assert_equal(-1_010.to_d, compra.lancamentos_caixa.sum(:valor))

    registrar_operacao(natureza: :venda, quantidade: 4, preco: 120, custos: 4,
      data: Date.new(2026, 1, 20))
    posicao = PosicaoAtual.find_by!(conta_investimento: @conta, ativo: @ativo)
    assert_equal 6.to_d, posicao.quantidade
    assert_equal 606.to_d, posicao.custo_total
    assert_equal 72.to_d, posicao.resultado_realizado

    registrar_operacao(natureza: :venda, quantidade: 6, preco: 110,
      data: Date.new(2026, 1, 25))
    posicao = PosicaoAtual.find_by!(conta_investimento: @conta, ativo: @ativo)
    assert_equal 0.to_d, posicao.quantidade
    assert_equal 0.to_d, posicao.custo_total
    assert_equal 126.to_d, posicao.resultado_realizado
  end

  test "posição vendida, cobertura parcial e cruzamento de zero preservam sinais" do
    registrar_operacao(natureza: :venda, quantidade: 10, preco: 100, custos: 10)
    posicao = PosicaoAtual.find_by!(conta_investimento: @conta, ativo: @ativo)
    assert_equal(-10.to_d, posicao.quantidade)
    assert_equal(-990.to_d, posicao.custo_total)

    registrar_operacao(natureza: :compra, quantidade: 4, preco: 80, custos: 4,
      data: Date.new(2026, 1, 20))
    posicao = PosicaoAtual.find_by!(conta_investimento: @conta, ativo: @ativo)
    assert_equal(-6.to_d, posicao.quantidade)
    assert_equal(-594.to_d, posicao.custo_total)
    assert_equal 72.to_d, posicao.resultado_realizado

    registrar_operacao(natureza: :compra, quantidade: 8, preco: 90, custos: 8,
      data: Date.new(2026, 1, 25))
    posicao = PosicaoAtual.find_by!(conta_investimento: @conta, ativo: @ativo)
    assert_equal 2.to_d, posicao.quantidade
    assert_equal 182.to_d, posicao.custo_total
    assert_equal 120.to_d, posicao.resultado_realizado
  end

  test "evento confirmado é imutável e reversão é única e atômica" do
    evento = registrar_operacao(natureza: :compra, quantidade: 3, preco: 10)
    assert_not evento.update(observacao: "mudança proibida")
    assert_not evento.operacao.update(preco_unitario: 11)

    reversao = ReverterEventoFinanceiro.call(evento:, usuario: @usuario)
    assert reversao.confirmado?
    assert_equal 0.to_d, PosicaoAtual.find_by(conta_investimento: @conta, ativo: @ativo)&.quantidade.to_d
    assert_equal 0.to_d, ConsultarSaldosCaixa.call(carteira: @carteira).fetch(@caixa_brl.id)
    assert_equal reversao, ReverterEventoFinanceiro.call(evento:, usuario: @usuario)
  end

  test "falha ao confirmar reversão não deixa rascunho órfão" do
    evento = EventoFinanceiro.create!(carteira: @carteira, usuario_responsavel: @usuario,
      tipo: :operacao, origem: :manual, estado: :rascunho, data_competencia: Date.current)

    assert_raises(ActiveRecord::RecordInvalid) do
      ReverterEventoFinanceiro.call(evento:, usuario: @usuario)
    end

    assert_nil evento.reload.reversao
    assert_equal 1, @carteira.eventos_financeiros.count
  end

  test "chave de idempotência não duplica evento nem lançamento" do
    atributos = atributos_operacao(natureza: :compra, quantidade: 2, preco: 10)
    primeiro = RegistrarOperacao.call(carteira: @carteira, usuario: @usuario,
      atributos:, chave_idempotencia: "ordem-123")
    segundo = RegistrarOperacao.call(carteira: @carteira, usuario: @usuario,
      atributos:, chave_idempotencia: "ordem-123")
    assert_equal primeiro, segundo
    assert_equal 1, primeiro.lancamentos_caixa.count
    assert_equal 1, @carteira.eventos_financeiros.where(chave_idempotencia: "ordem-123").count
  end

  test "chave de idempotência vazia é normalizada e não colide" do
    2.times do |indice|
      RegistrarOperacao.call(carteira: @carteira, usuario: @usuario,
        atributos: atributos_operacao(natureza: :compra, quantidade: 1, preco: 10 + indice),
        chave_idempotencia: "")
    end
    assert_equal 2, @carteira.eventos_financeiros.count
    assert @carteira.eventos_financeiros.pluck(:chave_idempotencia).all?(&:nil?)
  end

  test "models não contornam confirmação nem imutabilidade dos fatos" do
    rascunho = RegistrarOperacao.call(carteira: @carteira, usuario: @usuario,
      atributos: atributos_operacao(natureza: :compra, quantidade: 1, preco: 10), confirmar: false)
    assert_not rascunho.update(estado: :confirmado)
    evento = ConfirmarEventoFinanceiro.call(rascunho)
    assert_not evento.lancamentos_caixa.create(conta_caixa: @caixa_brl,
      data_efetiva: Date.current, natureza: "indevido", valor: 1).persisted?
    assert_not evento.create_provento(conta_investimento: @conta, ativo: @ativo,
      tipo: :dividendo, quantidade_referencia: 1, valor_bruto: 1, tributos: 0,
      valor_liquido: 1, moeda: @brl, data_base: Date.current, data_pagamento: Date.current,
      taxa_conversao_base: 1, taxa_conversao_fiscal: 1).persisted?
  end

  test "exclusão transacional remove detalhe de rascunho" do
    rascunho = RegistrarOperacao.call(carteira: @carteira, usuario: @usuario,
      atributos: atributos_operacao(natureza: :compra, quantidade: 1, preco: 10), confirmar: false)
    assert_difference -> { EventoFinanceiro.count }, -1 do
      assert_difference -> { Operacao.count }, -1 do
        ExcluirEventoFinanceiroRascunho.call(rascunho)
      end
    end
  end

  test "falha na projeção reverte confirmação e livro de caixa" do
    outra = ContaInvestimento.create!(carteira: @carteira, corretora: @corretora, nome: "Conta 2")
    evento = registrar_operacao(natureza: :compra, quantidade: 2, preco: 10)
    rascunho = RegistrarTransferenciaCustodia.call(carteira: @carteira, usuario: @usuario,
      atributos: { conta_origem: @conta, conta_destino: outra, ativo: @ativo, quantidade: 3 },
      data_competencia: Date.new(2026, 1, 20), confirmar: false)
    assert_raises(ArgumentError) { ConfirmarEventoFinanceiro.call(rascunho) }
    assert rascunho.reload.rascunho?
    assert_equal 0, rascunho.lancamentos_caixa.count
    assert_equal 2.to_d, PosicaoAtual.find_by!(conta_investimento: @conta, ativo: @ativo).quantidade
    assert evento.confirmado?
  end
end
