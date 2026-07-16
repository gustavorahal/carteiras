class Carteira < ApplicationRecord
  belongs_to :investidor, inverse_of: :carteiras
  belongs_to :moeda_base, class_name: "Moeda"
  has_many :contas_investimento, class_name: "ContaInvestimento", inverse_of: :carteira
  has_many :contas_caixa, through: :contas_investimento
  has_many :eventos_financeiros, class_name: "EventoFinanceiro", inverse_of: :carteira
  has_many :posicoes_atuais, class_name: "PosicaoAtual", through: :contas_investimento
  has_many :resumos_diarios, class_name: "ResumoDiarioCarteira", inverse_of: :carteira

  validates :nome, presence: true, uniqueness: { scope: :investidor_id }

  scope :ativas, -> { where(arquivado_em: nil) }
end
