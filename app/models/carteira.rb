class Carteira < ApplicationRecord
  has_many :operacoes, -> { includes(:ativo, :carteira, :corretora).order(data: :desc) }
  belongs_to :investidor
  belongs_to :referencia

end
