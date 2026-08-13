class TransferenciaCustodia < ApplicationRecord
  self.table_name = "transferencias_custodia"
  include FatoFinanceiroImutavel

  belongs_to :transacao_financeira, inverse_of: :transferencia_custodia
  belongs_to :conta_origem, class_name: "ContaInvestimento", inverse_of: :transferencias_custodia_origem
  belongs_to :conta_destino, class_name: "ContaInvestimento", inverse_of: :transferencias_custodia_destino
  belongs_to :ativo, inverse_of: :transferencias_custodia

  validates :quantidade, numericality: { greater_than: 0 }
  validate :contas_distintas

  private

  def contas_distintas
    errors.add(:conta_destino, "deve ser diferente da origem") if conta_origem_id == conta_destino_id
  end
end
