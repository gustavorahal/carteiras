class EventoCorporativo < ApplicationRecord
  self.table_name = "eventos_corporativos"
  include ConfirmadoImutavel
  belongs_to :evento_financeiro, inverse_of: :evento_corporativo
  belongs_to :conta_investimento
  belongs_to :ativo_origem, class_name: "Ativo"
  belongs_to :ativo_destino, class_name: "Ativo", optional: true
  belongs_to :moeda, optional: true

  enum :tipo, { desdobramento: "desdobramento", grupamento: "grupamento", incorporacao: "incorporacao" }, validate: true
  enum :regra_alocacao_custo, {
    preservar: "preservar", realizar_fracao: "realizar_fracao"
  }, validate: true
  validates :fator, numericality: { greater_than: 0 }, allow_nil: true
  validates :quantidade_final, :valor_fracao, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :taxa_conversao_base, numericality: { greater_than: 0 }
  validates :percentual_custo_fracao, numericality: { greater_than: 0, less_than_or_equal_to: 100 },
    allow_nil: true
  validate :parametros_suficientes

  private

  def parametros_suficientes
    if (desdobramento? || grupamento?) && fator.blank? && quantidade_final.blank?
      errors.add(:fator, "ou quantidade final deve ser informado")
    end
    errors.add(:ativo_destino, "é obrigatório") if incorporacao? && ativo_destino.blank?
    errors.add(:ativo_destino, "deve ser diferente do ativo de origem") if ativo_destino && ativo_destino == ativo_origem
    errors.add(:quantidade_final, "ou fator deve ser informado") if incorporacao? && quantidade_final.blank? && fator.blank?
    errors.add(:moeda, "é obrigatória quando há valor de fração") if valor_fracao&.positive? && moeda.blank?
    if valor_fracao&.positive? && !realizar_fracao?
      errors.add(:regra_alocacao_custo, "deve realizar a fração quando há valor em dinheiro")
    end
    if realizar_fracao? && (!valor_fracao&.positive? || percentual_custo_fracao.blank?)
      errors.add(:percentual_custo_fracao, "é obrigatório para realizar a fração em dinheiro")
    end
  end
end
