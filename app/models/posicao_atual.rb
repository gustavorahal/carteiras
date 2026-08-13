class PosicaoAtual < ApplicationRecord
  self.table_name = "posicoes_atuais"
  belongs_to :conta_investimento, inverse_of: :posicoes_atuais
  belongs_to :ativo
  belongs_to :ultima_transacao, class_name: "TransacaoFinanceira"

  validates :ativo_id, uniqueness: { scope: :conta_investimento_id }
  validates :quantidade, numericality: { greater_than: 0 }
  validates :custo_total_local, :custo_total_base, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :custos_preenchidos_em_conjunto

  private

  def custos_preenchidos_em_conjunto
    return if custo_total_local.nil? == custo_total_base.nil?

    errors.add(:custo_total_base, "deve acompanhar o custo total local")
  end
end
