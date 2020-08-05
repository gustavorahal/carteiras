class Carteira < ApplicationRecord
  has_many :carteira_ativos
  belongs_to :investidor

  def books_porcentagem
    carteira_ativos.where(valido: true).group(:book).order(:book).sum(:porcentagem)
  end

end
