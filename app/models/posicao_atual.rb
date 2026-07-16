class PosicaoAtual < ApplicationRecord
  self.table_name = "posicoes_atuais"
  belongs_to :conta_investimento, inverse_of: :posicoes_atuais
  belongs_to :ativo
  belongs_to :ultimo_evento_aplicado, class_name: "EventoFinanceiro", optional: true

  validates :ativo_id, uniqueness: { scope: :conta_investimento_id }

  def preco_medio = quantidade.zero? ? 0.to_d : custo_total.abs / quantidade.abs
end
