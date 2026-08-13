class ClassificacaoAtivoCarteira < ApplicationRecord
  self.table_name = "classificacoes_ativos_carteira"

  CATEGORIAS = %w[acoes renda_fixa internacional commodities fundos outros].freeze
  SUGESTOES_POR_TIPO = {
    "acao" => "acoes", "fii" => "fundos", "fundo" => "fundos",
    "renda_fixa" => "renda_fixa", "criptoativo" => "outros", "outro" => "outros"
  }.freeze

  belongs_to :carteira, inverse_of: :classificacoes_ativos
  belongs_to :ativo, inverse_of: :classificacoes_carteira

  validates :categoria, inclusion: { in: CATEGORIAS }
  validates :ativo_id, uniqueness: { scope: :carteira_id }

  def self.descricao(categoria)
    return I18n.t("financeiro.categorias_alocacao.nao_classificado") if categoria.blank?

    I18n.t("financeiro.categorias_alocacao.#{categoria}")
  end

  def self.opcoes
    CATEGORIAS.map { |categoria| [descricao(categoria), categoria] }
  end

  def self.sugestao(ativo, carteira:)
    return "internacional" if ativo.moeda_negociacao_id != carteira.moeda_base_id

    SUGESTOES_POR_TIPO[ativo.tipo]
  end
end
