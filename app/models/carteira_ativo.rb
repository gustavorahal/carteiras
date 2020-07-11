class CarteiraAtivo < ApplicationRecord
  belongs_to :carteira
  belongs_to :ativo
  belongs_to :investidor
end
