class Moeda < ApplicationRecord
  enum :tipo, { fiduciaria: "fiduciaria", criptoativo: "criptoativo" }, validate: true

  before_validation { self.codigo = codigo.to_s.strip.upcase }

  validates :codigo, :nome, presence: true
  validates :codigo, uniqueness: true
  validates :casas_decimais, inclusion: { in: 0..18 }

  scope :ativas, -> { where(arquivado_em: nil) }
end
