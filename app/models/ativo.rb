class Ativo < ApplicationRecord
  include Arquivavel
  include Normalizavel

  TIPOS = %w[acao fii fundo etf renda_fixa criptoativo outro].freeze

  belongs_to :moeda_negociacao, class_name: "Moeda", inverse_of: :ativos
  has_many :negociacoes, inverse_of: :ativo
  has_many :proventos, inverse_of: :ativo
  has_many :cotacoes_ativos, class_name: "CotacaoAtivo", inverse_of: :ativo

  normaliza_texto :codigo, :mercado, maiusculo: true
  normaliza_texto :descricao, :cnpj
  before_validation :normalizar_cnpj
  validates :codigo, :mercado, presence: true
  validates :codigo, uniqueness: { scope: :mercado }
  validates :tipo, inclusion: { in: TIPOS }
  validates :cnpj, format: { with: /\A\d{14}\z/ }, allow_nil: true
  validate :identidade_imutavel_apos_referencia, on: :update

  private

  def normalizar_cnpj
    self.cnpj = cnpj&.gsub(/\D/, "").presence
  end

  def identidade_imutavel_apos_referencia
    return unless will_save_change_to_codigo? || will_save_change_to_mercado? || will_save_change_to_moeda_negociacao_id?
    return unless negociacoes.exists? || proventos.exists? || cotacoes_ativos.exists?

    errors.add(:base, "código, mercado e moeda não podem mudar após a primeira referência")
  end
end
