class Ativo < ApplicationRecord
  belongs_to :moeda_negociacao, class_name: "Moeda"
  belongs_to :moeda_exposicao, class_name: "Moeda"
  has_many :cotacoes, class_name: "CotacaoAtivo", inverse_of: :ativo

  enum :tipo, {
    acao: "acao", fii: "fii", fundo: "fundo", criptomoeda: "criptomoeda",
    tesouro: "tesouro", etf: "etf", debenture: "debenture", cra: "cra", cdb: "cdb"
  }, validate: true

  before_validation :normalizar_codigo_e_cnpj

  validates :codigo, :mercado, presence: true
  validates :codigo, uniqueness: { scope: :mercado }
  validates :cnpj, presence: true, if: :fundo?

  scope :ativos, -> { where(arquivado_em: nil) }

  def nome_amigavel
    return "#{codigo} (#{cnpj})" if fundo?
    descricao.blank? ? codigo : "#{codigo} (#{descricao})"
  end

  def usd? = moeda_negociacao.codigo == "USD"
  def brl? = moeda_negociacao.codigo == "BRL"
  def na_bolsa? = tipo.in?(self.class.tipos_bolsa)

  def self.tipos_bolsa = %w[acao fii etf]

  private

  def normalizar_codigo_e_cnpj
    self.codigo = codigo.to_s.strip.upcase
    self.cnpj = cnpj.to_s.gsub(/\D/, "").presence
  end
end
