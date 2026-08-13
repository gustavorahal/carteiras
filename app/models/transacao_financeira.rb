class TransacaoFinanceira < ApplicationRecord
  self.table_name = "transacoes_financeiras"
  include FatoFinanceiroImutavel
  include Normalizavel

  TIPOS = %w[nota_negociacao provento movimentacao_caixa saldo_inicial transferencia_custodia evento_corporativo reversao].freeze
  ORIGENS = %w[manual importacao sistema].freeze
  ESTADOS = %w[rascunho confirmada].freeze

  belongs_to :investidor, inverse_of: :transacoes_financeiras
  belongs_to :criado_por, class_name: "User", inverse_of: :transacoes_criadas
  belongs_to :confirmado_por, class_name: "User", inverse_of: :transacoes_confirmadas, optional: true
  belongs_to :transacao_revertida, class_name: "TransacaoFinanceira", optional: true
  has_one :reversao, class_name: "TransacaoFinanceira", foreign_key: :transacao_revertida_id, inverse_of: :transacao_revertida
  has_one :nota_negociacao, inverse_of: :transacao_financeira
  has_one :provento, inverse_of: :transacao_financeira
  has_one :movimentacao_caixa, inverse_of: :transacao_financeira
  has_one :saldo_inicial, inverse_of: :transacao_financeira
  has_one :transferencia_custodia, inverse_of: :transacao_financeira
  has_one :evento_corporativo, inverse_of: :transacao_financeira
  belongs_to :importacao_financeira, inverse_of: :transacoes_financeiras, optional: true
  has_many :lancamentos_caixa, -> { order(:ordem) }, class_name: "LancamentoCaixa", inverse_of: :transacao_financeira

  normaliza_texto :observacao, :chave_idempotencia
  validates :tipo, inclusion: { in: TIPOS }
  validates :origem, inclusion: { in: ORIGENS }
  validates :estado, inclusion: { in: ESTADOS }
  validates :data_competencia, presence: true
  validates :ordem_na_data, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :chave_idempotencia, uniqueness: { scope: :investidor_id }, allow_nil: true

  scope :confirmadas, -> { where(estado: "confirmada") }
  scope :ordem_replay, -> { order(:data_competencia, :ordem_na_data, :id) }

  def confirmada?
    estado == "confirmada"
  end

  def rascunho?
    estado == "rascunho"
  end

  def reversao?
    tipo == "reversao"
  end

  def revertida?
    reversao.present?
  end

  def estado_anterior_confirmado?
    estado_in_database == "confirmada"
  end
end
