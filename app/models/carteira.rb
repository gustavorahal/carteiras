class Carteira < ApplicationRecord
  has_many :carteira_ativos
  belongs_to :investidor

end
