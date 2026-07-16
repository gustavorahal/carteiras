class EventoFinanceiro < ApplicationRecord
  attr_reader :confirmacao_em_curso
  self.table_name = "eventos_financeiros"
  belongs_to :carteira, inverse_of: :eventos_financeiros
  belongs_to :usuario_responsavel, class_name: "User", inverse_of: :eventos_financeiros
  belongs_to :evento_revertido, class_name: "EventoFinanceiro", optional: true
  has_one :reversao, class_name: "EventoFinanceiro", foreign_key: :evento_revertido_id, inverse_of: :evento_revertido

  has_one :operacao, inverse_of: :evento_financeiro
  has_one :provento, inverse_of: :evento_financeiro
  has_one :movimentacao_caixa, inverse_of: :evento_financeiro
  has_one :transferencia_caixa, inverse_of: :evento_financeiro
  has_one :transferencia_custodia, inverse_of: :evento_financeiro
  has_one :evento_corporativo, inverse_of: :evento_financeiro
  has_many :lancamentos_caixa, class_name: "LancamentoCaixa", inverse_of: :evento_financeiro

  enum :tipo, {
    operacao: "operacao", provento: "provento", movimentacao_caixa: "movimentacao_caixa",
    transferencia_caixa: "transferencia_caixa", transferencia_custodia: "transferencia_custodia",
    evento_corporativo: "evento_corporativo", reversao: "reversao"
  }, validate: true
  enum :origem, { manual: "manual", importacao: "importacao", sistema: "sistema" }, validate: true
  enum :estado, { rascunho: "rascunho", confirmado: "confirmado" }, validate: true

  validates :data_competencia, presence: true
  validates :chave_idempotencia, uniqueness: { scope: :carteira_id }, allow_nil: true
  validate :reversao_coerente

  before_update :impedir_alteracao_confirmada
  before_destroy :impedir_exclusao_confirmada
  validate :confirmacao_somente_pelo_servico

  scope :ordenados_para_replay, -> { order(:data_competencia, :sequencia_na_data, :id) }

  def detalhe
    public_send(tipo) unless reversao?
  end
  def revertido? = reversao&.confirmado? || false

  def confirmacao_em_curso? = confirmacao_em_curso == true

  private

  attr_writer :confirmacao_em_curso

  def impedir_alteracao_confirmada
    return unless estado_in_database == "confirmado"
    errors.add(:base, "Eventos confirmados são imutáveis")
    throw :abort
  end

  def impedir_exclusao_confirmada = impedir_alteracao_confirmada

  def confirmacao_somente_pelo_servico
    return if confirmacao_em_curso?
    return unless confirmado? && (new_record? || estado_in_database != "confirmado")
    errors.add(:estado, "só pode ser confirmado pelo serviço de domínio")
  end

  def reversao_coerente
    if reversao? != evento_revertido_id.present?
      errors.add(:evento_revertido, "deve ser informado somente em uma reversão")
    elsif evento_revertido && evento_revertido.carteira_id != carteira_id
      errors.add(:evento_revertido, "deve pertencer à mesma carteira")
    end
  end
end
