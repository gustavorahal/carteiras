class Ativo < ApplicationRecord
  has_many :carteira_ativos

  enum tipo: {
      acao: 1,
      fii: 2,
      moeda: 3,
      fundo: 4,
      criptomoeda: 5,
      tesouro: 6
  }

end
