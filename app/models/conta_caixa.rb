class ContaCaixa < ApplicationRecord
  self.table_name = "contas_caixa"
  belongs_to :conta_investimento, inverse_of: :contas_caixa
  belongs_to :moeda
  has_many :lancamentos_caixa, class_name: "LancamentoCaixa", inverse_of: :conta_caixa

  validates :moeda_id, uniqueness: { scope: :conta_investimento_id }

  delegate :carteira, :corretora, to: :conta_investimento

  def nome_completo = "#{conta_investimento.nome} — #{moeda.codigo}"
end
