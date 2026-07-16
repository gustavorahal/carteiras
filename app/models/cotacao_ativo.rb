class CotacaoAtivo < ApplicationRecord
  self.table_name = "cotacoes_ativos"
  belongs_to :ativo, inverse_of: :cotacoes
  belongs_to :moeda
  belongs_to :fonte_cotacao
  belongs_to :usuario_responsavel, class_name: "User", optional: true

  validates :data, presence: true, uniqueness: { scope: :ativo_id }
  validates :preco, numericality: { greater_than: 0 }
end
