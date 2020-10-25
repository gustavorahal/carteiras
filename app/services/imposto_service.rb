class ImpostoService

  # @return valor do imposto em R$
  def irpf(operacao)
    return unless operacao == 'V' # venda

    if operacao.quantidade.negative?
      quant_pos = operacao.quantidade * -1
    else
      quant_pos = operacao.quantidade
    end
    v_operacao_venda = operacao.valor_unit * operacao.usdbrl * quant_pos
    cap = CarteiraAtivoPosicao.new(operacao.carteira_ativo.id, Date.today)
    pm = cap.preco_medio
    v_medio = pm * quant_pos

    sum_custos_oper = Operacao
                          .where(carteira_ativo_id: carteira_ativo_id)
                          .where("data::date >= ? AND data::date <= ?", cap.data_montagem, data)
                          .sum('(co_taxa + co_emolumentos + co_corretagem + co_iss_iof + co_irrf + co_outros) * usdbrl')

    puts "Data mont #{cap.data_montagem}"
    puts "Preço Medio #{pm}"
    puts "Valor Medio #{v_medio}"
    puts "Valor Venda #{v_operacao_venda}"
    puts "Lucro Líquida #{v_operacao_venda - v_medio}"
    puts "Custos Oper #{sum_custos_oper}"

    diff = v_operacao_venda - v_medio - sum_custos_oper
    imposto = 0

    if operacao.carteira_ativo.ativo.tipo == 'acao'
      imposto = diff * 0.15
    elsif operacao.carteira_ativo.ativo.tipo == 'fii'
      imposto = diff * 0.20
    end

    imposto
  end

end