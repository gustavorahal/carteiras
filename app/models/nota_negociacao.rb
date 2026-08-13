class NotaNegociacao < ApplicationRecord
  self.table_name = "notas_negociacao"
  include FatoFinanceiroImutavel

  belongs_to :transacao_financeira, inverse_of: :nota_negociacao
  belongs_to :conta_caixa
  has_many :negociacoes, -> { order(:ordem) }, inverse_of: :nota_negociacao

  validates :data_negociacao, :data_liquidacao, presence: true
  validates :custo_operacional_total, numericality: { greater_than_or_equal_to: 0 }
  validates :taxa_conversao_base, numericality: { greater_than: 0 }
end
