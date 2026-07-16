class ContaInvestimento < ApplicationRecord
  self.table_name = "contas_investimento"
  belongs_to :carteira, inverse_of: :contas_investimento
  belongs_to :corretora, inverse_of: :contas_investimento
  has_many :contas_caixa, class_name: "ContaCaixa", inverse_of: :conta_investimento
  has_many :posicoes_atuais, class_name: "PosicaoAtual", inverse_of: :conta_investimento

  validates :nome, presence: true, uniqueness: { scope: :carteira_id }
  validates :identificador_externo, uniqueness: { scope: :corretora_id }, allow_nil: true

  before_validation { self.identificador_externo = identificador_externo.presence }

  scope :ativas, -> { where(arquivado_em: nil) }
end
