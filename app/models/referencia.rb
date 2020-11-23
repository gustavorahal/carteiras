class Referencia < ApplicationRecord
  has_many :carteiras
  has_many :referencia_ativos, -> { includes :ativo }

  def ativos_por_book
    lista = {}
    referencia_ativos.where.not(porcentagem: 0).order(:book).each do |ref_ativo|
      lista[ref_ativo.book] = [] unless ref_ativo.book.in? lista
      lista[ref_ativo.book].push ref_ativo.ativo
    end

    lista
  end

  def porcentagens_por_book
    referencia_ativos
        .where.not(porcentagem: 0)
        .group(:book)
        .order(:book)
        .sum(:porcentagem)
  end

  def porcentagem(ativo)
    ra = referencia_ativos.find_by(ativo: ativo)
    return 0 if ra.nil?

    ra.porcentagem
  end

end