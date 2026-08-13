class ContaCaixa < ApplicationRecord
  self.table_name = "contas_caixa"
  include Arquivavel

  belongs_to :conta_investimento, inverse_of: :contas_caixa
  belongs_to :moeda, inverse_of: :contas_caixa
  has_many :lancamentos_caixa, class_name: "LancamentoCaixa", inverse_of: :conta_caixa
  has_many :saldos_iniciais_caixa, class_name: "SaldoInicialCaixa", inverse_of: :conta_caixa

  delegate :carteira, :investidor, :espaco, to: :conta_investimento
  validates :moeda_id, uniqueness: { scope: :conta_investimento_id }
  validate :ascendencia_disponivel, on: :create

  private

  def ascendencia_disponivel
    conta = conta_investimento
    errors.add(:conta_investimento, "está arquivada") if conta&.arquivado? || conta&.carteira&.arquivado? || conta&.investidor&.arquivado? || conta&.espaco&.arquivado?
    errors.add(:moeda, "está arquivada") if moeda&.arquivado?
  end
end
