class Instituicao < ApplicationRecord
  include Arquivavel
  include Normalizavel

  has_many :contas_investimento, class_name: "ContaInvestimento", inverse_of: :instituicao
  normaliza_texto :nome
  validates :nome, presence: true, uniqueness: { case_sensitive: false }
end
