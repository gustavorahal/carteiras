require "test_helper"

class TransacoesFinanceirasTest < ActiveSupport::TestCase
  test "idempotência devolve o fato existente e detecta conflito de tipo" do
    primeira = TransacoesFinanceiras.criar_rascunho(tipo: "movimentacao_caixa", investidor: @investidor,
      usuario: @usuario, atributos: atributos_aporte, chave_idempotencia: "abc")
    repetida = TransacoesFinanceiras.criar_rascunho(tipo: "movimentacao_caixa", investidor: @investidor,
      usuario: @usuario, atributos: atributos_aporte(valor: "999"), chave_idempotencia: "abc")
    assert_equal primeira, repetida
    assert_equal "1000.0", repetida.movimentacao_caixa.valor_destino.to_s
    assert_raises(Financeiro::ConflitoIdempotencia) do
      TransacoesFinanceiras.criar_rascunho(tipo: "provento", investidor: @investidor,
        usuario: @usuario, atributos: {}, chave_idempotencia: "abc")
    end
  end

  test "aporte confirma lançamento assinado e permite caixa negativo em resgate" do
    aporte = criar_e_confirmar("movimentacao_caixa", atributos_aporte)
    assert_equal "confirmada", aporte.estado
    assert_equal BigDecimal("1000"), aporte.lancamentos_caixa.sum(:valor)
    resgate = criar_e_confirmar("movimentacao_caixa", { tipo_movimentacao: "resgate",
      conta_caixa_origem_id: @caixa_brl.id, valor: "1200", data_efetiva: "2026-01-03" })
    assert_equal BigDecimal("-1200"), resgate.lancamentos_caixa.first.valor
  end

  test "nota multilinha rateia custo com resíduo e preview coincide com confirmação" do
    outro = Ativo.create!(codigo: "VALE3", mercado: "B3", tipo: "acao", moeda_negociacao: @brl)
    atributos = atributos_nota(custo: "1").merge(negociacoes: [
      { ativo_id: @ativo.id, natureza: "compra", quantidade: "1", preco_unitario: "10" },
      { ativo_id: outro.id, natureza: "compra", quantidade: "1", preco_unitario: "20" }
    ])
    previa = TransacoesFinanceiras.prever(tipo: "nota_negociacao", investidor: @investidor, usuario: @usuario, atributos:)
    custos = previa.detalhe_normalizado[:negociacoes].pluck(:custo_alocado)
    assert_equal BigDecimal("1"), custos.sum
    transacao = criar_e_confirmar("nota_negociacao", atributos)
    assert_equal custos, transacao.nota_negociacao.negociacoes.order(:ordem).pluck(:custo_alocado)
    assert_equal BigDecimal("-31"), transacao.lancamentos_caixa.first.valor
    assert_equal 2, PosicaoAtual.count
  end

  test "long-only rejeita venda excedente e retroativa que remove lastro" do
    compra = criar_e_confirmar("nota_negociacao", atributos_nota(quantidade: "10", data: "2026-01-05"))
    criar_e_confirmar("nota_negociacao", atributos_nota(natureza: "venda", quantidade: "5", data: "2026-01-06"))
    assert_raises(Financeiro::HistoricoInvalido) do
      criar_e_confirmar("nota_negociacao", atributos_nota(natureza: "venda", quantidade: "6", data: "2026-01-07"))
    end
    assert_raises(Financeiro::HistoricoInvalido) { TransacoesFinanceiras.reverter(transacao: compra, usuario: @usuario) }
    assert_equal BigDecimal("5"), PosicaoAtual.find_by!(ativo: @ativo).quantidade
  end

  test "reversão cria tombstone e pernas opostas ligadas" do
    aporte = criar_e_confirmar("movimentacao_caixa", atributos_aporte)
    reversao = TransacoesFinanceiras.reverter(transacao: aporte, usuario: @usuario)
    assert_equal "reversao", reversao.tipo
    assert_equal -aporte.lancamentos_caixa.first.valor, reversao.lancamentos_caixa.first.valor
    assert_equal aporte.lancamentos_caixa.first, reversao.lancamentos_caixa.first.lancamento_original
    assert_raises(Financeiro::EstadoInvalido) { TransacoesFinanceiras.reverter(transacao: aporte, usuario: @usuario) }
  end

  test "correção substitui compra atomicamente preservando venda posterior" do
    compra = criar_e_confirmar("nota_negociacao", atributos_nota(quantidade: "10"))
    criar_e_confirmar("nota_negociacao", atributos_nota(natureza: "venda", quantidade: "8", data: "2026-01-06"))
    resultado = TransacoesFinanceiras.corrigir(transacao: compra, usuario: @usuario,
      atributos: atributos_nota(quantidade: "12"))
    assert resultado.original.revertida?
    assert_equal "reversao", resultado.reversao.tipo
    assert_equal "confirmada", resultado.substituta.estado
    assert_equal BigDecimal("4"), PosicaoAtual.find_by!(ativo: @ativo).quantidade
  end

  test "contrato rejeita float campo derivado desconhecido e payload parcial" do
    assert_raises(Financeiro::AtributosInvalidos) do
      TransacoesFinanceiras.prever(tipo: "nota_negociacao", investidor: @investidor, usuario: @usuario,
        atributos: atributos_nota.merge(custo_operacional_total: 1.0))
    end
    assert_raises(Financeiro::AtributosInvalidos) do
      TransacoesFinanceiras.prever(tipo: "nota_negociacao", investidor: @investidor, usuario: @usuario,
        atributos: atributos_nota.merge(valor_liquido: "10"))
    end
    rascunho = TransacoesFinanceiras.criar_rascunho(tipo: "nota_negociacao", investidor: @investidor, usuario: @usuario, atributos: atributos_nota)
    assert_raises(Financeiro::AtributosInvalidos) do
      TransacoesFinanceiras.atualizar_rascunho(transacao: rascunho, usuario: @usuario, atributos: { observacao: "parcial" })
    end
  end


  test "provento deriva líquido e reconhece caixa no pagamento" do
    atributos = { conta_caixa_id: @caixa_brl.id, ativo_id: @ativo.id, tipo_provento: "dividendo",
      data_base: "2026-01-03", data_pagamento: "2026-01-10", quantidade_referencia: "10",
      valor_bruto: "25", retencoes: "5", taxa_conversao_base: "1" }
    transacao = criar_e_confirmar("provento", atributos)
    assert_equal Date.new(2026, 1, 10), transacao.data_competencia
    assert_equal BigDecimal("20"), transacao.provento.valor_liquido
    assert_equal BigDecimal("20"), transacao.lancamentos_caixa.first.valor
  end

  test "transferência cruza carteiras do investidor e câmbio fica na mesma carteira" do
    outra = @investidor.carteiras.create!(nome: "Reserva", moeda_base: @brl)
    conta_outra = outra.contas_investimento.create!(nome: "Conta 2", instituicao: @instituicao)
    caixa_outra = conta_outra.contas_caixa.create!(moeda: @brl)
    transferencia = criar_e_confirmar("movimentacao_caixa", { tipo_movimentacao: "transferencia",
      conta_caixa_origem_id: @caixa_brl.id, conta_caixa_destino_id: caixa_outra.id,
      valor: "50", data_efetiva: "2026-01-04" })
    assert_equal [BigDecimal("-50"), BigDecimal("50")], transferencia.lancamentos_caixa.order(:ordem).pluck(:valor)
    assert_raises(Financeiro::EscopoInvalido) do
      TransacoesFinanceiras.prever(tipo: "movimentacao_caixa", investidor: @investidor, usuario: @usuario,
        atributos: { tipo_movimentacao: "cambio", conta_caixa_origem_id: @caixa_usd.id,
          conta_caixa_destino_id: caixa_outra.id, valor_origem: "10", valor_destino: "50", data_efetiva: "2026-01-04" })
    end
    cambio = criar_e_confirmar("movimentacao_caixa", { tipo_movimentacao: "cambio",
      conta_caixa_origem_id: @caixa_usd.id, conta_caixa_destino_id: @caixa_brl.id,
      valor_origem: "10", valor_destino: "50", data_efetiva: "2026-01-04" })
    assert_equal %w[cambio_saida cambio_entrada], cambio.lancamentos_caixa.order(:ordem).pluck(:natureza)
  end

  test "fato confirmado e detalhe são imutáveis pelo model" do
    transacao = criar_e_confirmar("nota_negociacao", atributos_nota)
    assert_not transacao.update(observacao: "alterada")
    assert_not transacao.nota_negociacao.update(custo_operacional_total: 99)
    assert_not transacao.destroy
  end

  test "não permite anexar filhos a fato confirmado" do
    transacao = criar_e_confirmar("nota_negociacao", atributos_nota)
    negociacao = transacao.nota_negociacao.negociacoes.build(ativo: @ativo, ordem: 2,
      natureza: "compra", quantidade: 1, preco_unitario: 1, custo_alocado: 0)
    lancamento = transacao.lancamentos_caixa.build(ordem: 2, conta_caixa: @caixa_brl,
      data_efetiva: transacao.data_competencia, natureza: "liquidacao_nota", valor: -1)

    assert_not negociacao.save
    assert_not lancamento.save
    assert_match(/imutável/, negociacao.errors.full_messages.to_sentence)
    assert_match(/imutável/, lancamento.errors.full_messages.to_sentence)
  end

  test "confirmação exige exatamente um detalhe compatível" do
    transacao = TransacoesFinanceiras.criar_rascunho(tipo: "nota_negociacao", investidor: @investidor,
      usuario: @usuario, atributos: atributos_nota)
    MovimentacaoCaixa.create!(transacao_financeira: transacao, tipo: "aporte",
      conta_caixa_destino: @caixa_brl, valor_destino: 10, data_efetiva: transacao.data_competencia)

    assert_raises(Financeiro::AtributosInvalidos) do
      TransacoesFinanceiras.confirmar(transacao:, usuario: @usuario)
    end
    assert transacao.reload.rascunho?
  end

  test "quantização é idêntica entre prévia e persistência e rejeita zero quantizado" do
    atributos = atributos_nota(custo: "0.0000000000006")
    previa = TransacoesFinanceiras.prever(tipo: "nota_negociacao", investidor: @investidor,
      usuario: @usuario, atributos:)
    assert_equal BigDecimal("0.000000000001"), previa.detalhe_normalizado[:custo_operacional_total]
    confirmada = criar_e_confirmar("nota_negociacao", atributos)
    assert_equal previa.detalhe_normalizado[:custo_operacional_total], confirmada.nota_negociacao.custo_operacional_total

    assert_raises(Financeiro::AtributosInvalidos) do
      TransacoesFinanceiras.prever(tipo: "movimentacao_caixa", investidor: @investidor, usuario: @usuario,
        atributos: atributos_aporte(valor: "0.0000000000004"))
    end
    assert_raises(Financeiro::AtributosInvalidos) do
      TransacoesFinanceiras.prever(tipo: "nota_negociacao", investidor: @investidor, usuario: @usuario,
        atributos: atributos_nota(quantidade: "0.0000000001", preco: "0.000000000001"))
    end
  end

  test "correção rejeita ordem diferente da original" do
    original = criar_e_confirmar("nota_negociacao", atributos_nota)
    assert_raises(Financeiro::AtributosInvalidos) do
      TransacoesFinanceiras.corrigir(transacao: original, usuario: @usuario,
        atributos: atributos_nota.merge(ordem_na_data: original.ordem_na_data + 1))
    end
    assert_not original.reload.revertida?
  end

  test "rascunho futuro pode ser previsto mas só é confirmado na competência" do
    data_futura = Date.current + 2
    atributos = atributos_nota(data: data_futura.iso8601)
    previa = TransacoesFinanceiras.prever(tipo: "nota_negociacao", investidor: @investidor,
      usuario: @usuario, atributos:)
    rascunho = TransacoesFinanceiras.criar_rascunho(tipo: "nota_negociacao", investidor: @investidor,
      usuario: @usuario, atributos:)

    assert_equal data_futura, previa.data_competencia
    assert_raises(Financeiro::AtributosInvalidos) do
      TransacoesFinanceiras.confirmar(transacao: rascunho, usuario: @usuario)
    end
    assert rascunho.reload.rascunho?
    assert_empty ConsultasFinanceiras.posicao_atual(carteira: @carteira, usuario: @usuario).itens
  end
end
