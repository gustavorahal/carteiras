class MovimentacaoCaixa < ApplicationRecord
  self.table_name = "movimentacoes_caixa"
  include ConfirmadoImutavel
  belongs_to :evento_financeiro, inverse_of: :movimentacao_caixa
  belongs_to :conta_caixa

  enum :natureza, { aporte: "aporte", resgate: "resgate", ajuste: "ajuste" }, validate: true
  enum :direcao, { entrada: "entrada", saida: "saida" }, validate: true
  validates :valor, numericality: { greater_than: 0 }
  validate :natureza_e_direcao_coerentes

  private

  def natureza_e_direcao_coerentes
    errors.add(:direcao, "deve ser entrada para aporte") if aporte? && !entrada?
    errors.add(:direcao, "deve ser saída para resgate") if resgate? && !saida?
  end
end
