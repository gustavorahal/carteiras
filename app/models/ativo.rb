class Ativo < ApplicationRecord
  has_many :cotacoes
  has_many :referencia_ativos

  enum tipo: {
      acao: 1,
      fii: 2,
      moeda: 3,
      fundo: 4,
      criptomoeda: 5,
      tesouro: 6,
      etf: 7
  }

  def nome_amigavel
    if descricao.blank?
      nome
    else
      "#{nome} (#{descricao})"
    end
  end

  def usd?
    moeda == 'USD'
  end

  def brl?
    moeda == 'BRL'
  end

  def na_bolsa?
    tipo.in? %w[acao fii etf]
  end

end
