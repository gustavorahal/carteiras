class ConsultarSaldosCaixa
  def self.call(carteira:, data: Date.current)
    LancamentoCaixa.joins(conta_caixa: :conta_investimento)
      .where(contas_investimento: { carteira_id: carteira.id })
      .where(data_efetiva: ..data)
      .group(:conta_caixa_id)
      .sum(:valor)
  end
end
