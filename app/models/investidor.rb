class Investidor < ApplicationRecord
  include Arquivavel
  include Normalizavel

  belongs_to :espaco, inverse_of: :investidores
  has_many :carteiras, inverse_of: :investidor
  has_many :transacoes_financeiras, class_name: "TransacaoFinanceira", inverse_of: :investidor
  has_many :importacoes_financeiras, class_name: "ImportacaoFinanceira", inverse_of: :investidor

  normaliza_texto :nome
  validates :nome, presence: true, uniqueness: { scope: :espaco_id, case_sensitive: false }
  validate :espaco_disponivel, on: :create

  private

  def espaco_disponivel
    errors.add(:espaco, "está arquivado") if espaco&.arquivado?
  end
end
