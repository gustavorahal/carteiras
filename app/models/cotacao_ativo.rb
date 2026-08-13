class CotacaoAtivo < ApplicationRecord
  self.table_name = "cotacoes_ativos"
  belongs_to :ativo, inverse_of: :cotacoes_ativos
  belongs_to :fonte_cotacao, inverse_of: :cotacoes_ativos
  belongs_to :autor, class_name: "User", optional: true

  validates :data, presence: true
  validates :preco, numericality: { greater_than: 0 }
  validates :data, uniqueness: { scope: :ativo_id }
end
