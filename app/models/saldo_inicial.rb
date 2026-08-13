class SaldoInicial < ApplicationRecord
  self.table_name = "saldos_iniciais"
  include FatoFinanceiroImutavel

  belongs_to :transacao_financeira, inverse_of: :saldo_inicial
  belongs_to :conta_investimento, inverse_of: :saldos_iniciais
  belongs_to :ativo, inverse_of: :saldos_iniciais

  validates :quantidade, numericality: { greater_than: 0 }
  validates :custo_total_local, :custo_total_base, numericality: { greater_than_or_equal_to: 0 }
end
