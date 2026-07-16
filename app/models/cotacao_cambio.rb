class CotacaoCambio < ApplicationRecord
  self.table_name = "cotacoes_cambio"
  belongs_to :moeda_origem, class_name: "Moeda"
  belongs_to :moeda_destino, class_name: "Moeda"
  belongs_to :fonte_cotacao
  belongs_to :usuario_responsavel, class_name: "User", optional: true

  validates :data, presence: true, uniqueness: { scope: %i[moeda_origem_id moeda_destino_id] }
  validates :taxa, numericality: { greater_than: 0 }
  validate { errors.add(:moeda_destino, "deve ser diferente da origem") if moeda_origem == moeda_destino }
end
