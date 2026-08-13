class SaldoInicialCaixa < ApplicationRecord
  self.table_name = "saldos_iniciais_caixa"
  include FatoFinanceiroImutavel

  belongs_to :transacao_financeira, inverse_of: :saldo_inicial_caixa
  belongs_to :conta_caixa, inverse_of: :saldos_iniciais_caixa

  validates :valor, numericality: { other_than: 0 }
end
