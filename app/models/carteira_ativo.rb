class CarteiraAtivo < ApplicationRecord
  has_many :operacoes
  belongs_to :ativo
  belongs_to :carteira
end
