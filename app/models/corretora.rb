class Corretora < ApplicationRecord
  has_many :contas_investimento, class_name: "ContaInvestimento", inverse_of: :corretora

  validates :nome, :pais, presence: true
  validates :nome, uniqueness: { scope: :pais }

  scope :ativas, -> { where(arquivado_em: nil) }
end
