class TransferenciaCaixa < ApplicationRecord
  self.table_name = "transferencias_caixa"
  include ConfirmadoImutavel
  belongs_to :evento_financeiro, inverse_of: :transferencia_caixa
  belongs_to :conta_caixa_origem, class_name: "ContaCaixa"
  belongs_to :conta_caixa_destino, class_name: "ContaCaixa"

  validates :valor, numericality: { greater_than: 0 }
  validate :contas_compativeis

  private

  def contas_compativeis
    return unless conta_caixa_origem && conta_caixa_destino
    errors.add(:conta_caixa_destino, "deve ser diferente da origem") if conta_caixa_origem == conta_caixa_destino
    errors.add(:conta_caixa_destino, "deve usar a mesma moeda") if conta_caixa_origem.moeda_id != conta_caixa_destino.moeda_id
    errors.add(:conta_caixa_destino, "deve pertencer à mesma carteira") if conta_caixa_origem.carteira != conta_caixa_destino.carteira
  end
end
