class TransferenciaCustodia < ApplicationRecord
  self.table_name = "transferencias_custodia"
  include ConfirmadoImutavel
  belongs_to :evento_financeiro, inverse_of: :transferencia_custodia
  belongs_to :conta_origem, class_name: "ContaInvestimento"
  belongs_to :conta_destino, class_name: "ContaInvestimento"
  belongs_to :ativo

  validates :quantidade, numericality: { greater_than: 0 }
  validate :contas_compativeis

  private

  def contas_compativeis
    return unless conta_origem && conta_destino
    errors.add(:conta_destino, "deve ser diferente da origem") if conta_origem == conta_destino
    errors.add(:conta_destino, "deve pertencer à mesma carteira") if conta_origem.carteira != conta_destino.carteira
  end
end
