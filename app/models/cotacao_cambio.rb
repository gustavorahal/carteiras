class CotacaoCambio < ApplicationRecord
  self.table_name = "cotacoes_cambio"
  belongs_to :moeda_origem, class_name: "Moeda"
  belongs_to :moeda_destino, class_name: "Moeda"
  belongs_to :fonte_cotacao, inverse_of: :cotacoes_cambio
  belongs_to :autor, class_name: "User"

  validates :data, presence: true, uniqueness: { scope: %i[moeda_origem_id moeda_destino_id] }
  validates :taxa, numericality: { greater_than: 0 }
  validate :moedas_distintas

  private

  def moedas_distintas
    errors.add(:moeda_destino, "deve ser diferente da moeda de origem") if moeda_origem_id == moeda_destino_id
  end
end
