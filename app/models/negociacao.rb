class Negociacao < ApplicationRecord
  include FatoFinanceiroImutavel

  belongs_to :nota_negociacao, inverse_of: :negociacoes
  belongs_to :ativo, inverse_of: :negociacoes
  delegate :transacao_financeira, to: :nota_negociacao

  validates :ordem, numericality: { only_integer: true, greater_than: 0 }, uniqueness: { scope: :nota_negociacao_id }
  validates :natureza, inclusion: { in: %w[compra venda] }
  validates :quantidade, :preco_unitario, numericality: { greater_than: 0 }
  validates :custo_alocado, numericality: { greater_than_or_equal_to: 0 }
end
