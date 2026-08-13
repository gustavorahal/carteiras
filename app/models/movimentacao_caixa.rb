class MovimentacaoCaixa < ApplicationRecord
  self.table_name = "movimentacoes_caixa"
  include FatoFinanceiroImutavel

  belongs_to :transacao_financeira, inverse_of: :movimentacao_caixa
  belongs_to :conta_caixa_origem, class_name: "ContaCaixa", optional: true
  belongs_to :conta_caixa_destino, class_name: "ContaCaixa", optional: true

  validates :tipo, inclusion: { in: %w[aporte resgate transferencia cambio] }
  validates :data_efetiva, presence: true
end
