class Carteira < ApplicationRecord
  has_many :operacoes, -> { includes(:ativo, :carteira, :corretora).order(data: :desc, created_at: :desc) }
  has_many :movimentacoes
  has_many :proventos
  belongs_to :investidor
  belongs_to :referencia

end
