class Referencia < ApplicationRecord
  has_many :carteiras
  has_many :referencia_ativos, -> { includes :ativo }
  has_many :ativos, through: :referencia_ativos

  # Quais ativos ainda NÃO tenho na referencia?
  def ativos_disponiveis
    Ativo.all - ativos.where.not('referencia_ativos.porcentagem': 0)
  end

  def ativos_por_book
    lista = {}
    referencia_ativos.where.not(porcentagem: 0).order(:book).each do |referencia_ativo|
      lista[referencia_ativo.book] = [] unless referencia_ativo.book.in? lista
      lista[referencia_ativo.book].push referencia_ativo.ativo
    end

    lista
  end

  def referencia_ativos_por_book
    lista = {}
    referencia_ativos.where.not(porcentagem: 0).order(:book).each do |referencia_ativo|
      lista[referencia_ativo.book] = [] unless referencia_ativo.book.in? lista
      lista[referencia_ativo.book].push referencia_ativo
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

  def sum_porcentagem_ativos
    referencia_ativos
        .where.not(porcentagem: 0)
        .sum(:porcentagem)
  end

  def porcentagem(ativo)
    ra = referencia_ativos.find_by(ativo: ativo)
    return 0 if ra.nil?

    ra.porcentagem
  end

end