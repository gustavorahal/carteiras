class Referencia < ApplicationRecord
  has_many :versoes, class_name: "VersaoReferencia", inverse_of: :referencia

  validates :nome, presence: true, uniqueness: true

  def versao_vigente_em(data)
    versoes.historicas.where(vigencia_inicial: ..data).order(vigencia_inicial: :desc).first
  end
end
