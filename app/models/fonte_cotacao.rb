class FonteCotacao < ApplicationRecord
  self.table_name = "fontes_cotacao"
  validates :nome, presence: true, uniqueness: true
  validates :prioridade, numericality: { greater_than_or_equal_to: 0 }
  scope :ativas, -> { where(arquivado_em: nil).order(:prioridade, :id) }
end
