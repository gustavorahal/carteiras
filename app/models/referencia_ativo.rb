class ReferenciaAtivo < ApplicationRecord
  belongs_to :referencia
  belongs_to :ativo

  validates :ativo_id, uniqueness: { scope: [ :referencia_id ] }

end