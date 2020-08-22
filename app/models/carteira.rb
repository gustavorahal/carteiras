class Carteira < ApplicationRecord
  has_many :carteira_ativos, -> { includes :ativo }
  has_many :ativos, through: :carteira_ativos
  belongs_to :investidor


  def ref_books_porcentagem_soma
    ref_books_porcentagem.values.sum
  end

  def ref_books_porcentagem
    carteira_ativos.where(valido: true).group(:book).order(:book).sum(:porcentagem)
  end

  def carteira_ativos_validos
    CarteiraAtivo
        .where(carteira_id: id, valido: true)
        .includes(:ativo)
        .order('ativos.descricao')
  end

  def carteira_ativos_todos
    CarteiraAtivo
        .where(carteira_id: id)
        .includes(:ativo)
        .order('ativos.nome')
  end

end
