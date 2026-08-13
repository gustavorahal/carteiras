class ImportacaoFinanceira < ApplicationRecord
  self.table_name = "importacoes_financeiras"

  ESTADOS = %w[pendente analisada concluida falhou].freeze

  belongs_to :investidor, inverse_of: :importacoes_financeiras
  belongs_to :conta_investimento, inverse_of: :importacoes_financeiras
  belongs_to :autor, class_name: "User", inverse_of: :importacoes_financeiras
  has_many :transacoes_financeiras, class_name: "TransacaoFinanceira", inverse_of: :importacao_financeira

  validates :nome_original, :checksum_sha256, :formato, :versao_parser, presence: true
  validates :checksum_sha256, uniqueness: { scope: :conta_investimento_id }
  validates :estado, inclusion: { in: ESTADOS }
  validate :conta_pertence_ao_investidor

  def pendencias
    Array(dados_extraidos["pendencias"])
  end

  def pronta_para_rascunhos?
    estado == "analisada" && pendencias.empty?
  end

  private

  def conta_pertence_ao_investidor
    return if conta_investimento.nil? || investidor.nil? || conta_investimento.investidor == investidor
    errors.add(:conta_investimento, "não pertence ao investidor")
  end
end
