class Operacao < ApplicationRecord
  belongs_to :carteira_ativo
  belongs_to :corretora

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
      .includes(:carteira_ativo)
      .where("carteira_ativos.carteira_id = #{carteira_id}")
      .order(data: :desc)
  end

  def custos_operacionais
    (co_taxa || 0) + (co_emolumentos || 0) + (co_corretagem || 0) + (co_iss_iof || 0) + (co_irrf || 0) + (co_outros || 0)
  end

end
