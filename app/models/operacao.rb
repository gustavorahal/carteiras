class Operacao < ApplicationRecord
  belongs_to :carteira_ativo

  enum operacao: {
      C: 1,
      V: 2,
      IR: 3
  }

  enum mon_ou_des: {
      M: 1,
      D: 2
  }

  def self.operacoes_carteira(carteira_id)
    Operacao
      .joins(carteira_ativo: :ativo)
      .where("carteira_ativos.carteira_id = #{carteira_id}")
      .order(data: :desc)
  end

  def custos_operacionais
    (co_taxa || 0) + (co_emolumentos || 0) + (co_corretagem || 0) + (co_iss_iof || 0) + (co_irrf || 0) + (co_outros || 0)
  end

  # @return valor do imposto em R$
  def irpf
    return unless operacao == 'V' # venda

    if quantidade.negative?
      quant_pos = quantidade * -1
    else
      quant_pos = quantidade
    end
    v_operacao_venda = valor_unit * usdbrl * quant_pos
    pm = carteira_ativo.preco_medio(data)
    pm = carteira_ativo.preco_medio(Date.today) if pm.nil?
    v_medio = pm * quant_pos

    sum_custos_oper = Operacao
                      .where(carteira_ativo_id: carteira_ativo_id)
                      .where("data >= ? AND data <= ?", carteira_ativo.data_montagem, data)
                      .sum('(co_taxa + co_emolumentos + co_corretagem + co_iss_iof + co_irrf + co_outros) * usdbrl')

    puts "Data mont #{carteira_ativo.data_montagem}"
    puts "Preço Medio #{pm}"
    puts "Valor Medio #{v_medio}"
    puts "Valor Venda #{v_operacao_venda}"
    puts "Lucro Líquida #{v_operacao_venda - v_medio}"
    puts "Custos Oper #{sum_custos_oper}"

    diff = v_operacao_venda - v_medio - sum_custos_oper
    imposto = 0

    if carteira_ativo.ativo.tipo == 'acao'
      imposto = diff * 0.15
    elsif carteira_ativo.ativo.tipo == 'fii'
      imposto = diff * 0.20
    end

    imposto
  end

end
