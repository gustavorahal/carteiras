class EventoCorporativo < ApplicationRecord
  self.table_name = "eventos_corporativos"
  include FatoFinanceiroImutavel

  TIPOS = %w[desdobramento grupamento bonificacao conversao incorporacao].freeze

  belongs_to :transacao_financeira, inverse_of: :evento_corporativo
  belongs_to :conta_investimento, inverse_of: :eventos_corporativos
  belongs_to :ativo_origem, class_name: "Ativo", inverse_of: :eventos_corporativos_origem
  belongs_to :ativo_destino, class_name: "Ativo", inverse_of: :eventos_corporativos_destino, optional: true

  validates :tipo, inclusion: { in: TIPOS }
  validates :quantidade_final, numericality: { greater_than: 0 }
  validate :ativos_coerentes

  private

  def ativos_coerentes
    if tipo.in?(%w[conversao incorporacao])
      errors.add(:ativo_destino, "é obrigatório e deve diferir da origem") if ativo_destino.blank? || ativo_destino == ativo_origem
    elsif ativo_destino.present?
      errors.add(:ativo_destino, "não se aplica a este tipo")
    end
  end
end
