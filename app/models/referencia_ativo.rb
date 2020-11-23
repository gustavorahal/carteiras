class ReferenciaAtivo < ApplicationRecord
  belongs_to :referencia
  belongs_to :ativo
end