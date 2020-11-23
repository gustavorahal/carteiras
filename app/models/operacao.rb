class Operacao < ApplicationRecord
  belongs_to :corretora
  belongs_to :ativo
  belongs_to :carteira

  enum operacao: {
      C: 1,
      V: 2,
      IR: 3,
      S: 4
  }

  enum mon_ou_des: {
      M: 1,
      D: 2
  }

  def custos_operacionais
    (co_taxa || 0) + (co_emolumentos || 0) + (co_corretagem || 0) + (co_iss_iof || 0) + (co_irrf || 0) + (co_outros || 0)
  end

end
