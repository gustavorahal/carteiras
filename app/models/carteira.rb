class Carteira < ApplicationRecord
  has_many :carteira_ativos, -> { includes :ativo, :corretora }
  has_many :ativos, through: :carteira_ativos
  belongs_to :investidor


  def carteira_ativos_books_porcentagem_soma
    carteira_ativos_por_book_porcentagem.values.sum
  end

  def carteira_ativos_por_book_porcentagem
    carteira_ativos
        .where.not(porcentagem: 0)
        .group(:book)
        .order(:book)
        .sum(:porcentagem)
  end

  def carteira_ativos_por_book
    carteira_ativos
        .where.not(porcentagem: 0)
        .order(:book, 'ativos.nome')
  end

  def carteira_ativos_todos
    carteira_ativos.order('ativos.nome')
  end

end
