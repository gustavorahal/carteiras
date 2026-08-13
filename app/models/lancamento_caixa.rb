class LancamentoCaixa < ApplicationRecord
  self.table_name = "lancamentos_caixa"
  include FatoFinanceiroImutavel

  belongs_to :transacao_financeira, inverse_of: :lancamentos_caixa
  belongs_to :conta_caixa, inverse_of: :lancamentos_caixa
  belongs_to :lancamento_original, class_name: "LancamentoCaixa", optional: true

  validates :ordem, numericality: { only_integer: true, greater_than: 0 }, uniqueness: { scope: :transacao_financeira_id }
  validates :natureza, inclusion: { in: %w[liquidacao_nota provento aporte resgate transferencia_saida transferencia_entrada cambio_saida cambio_entrada saldo_inicial] }
  validates :valor, numericality: { other_than: 0 }
end
