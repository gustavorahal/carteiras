class Ativo < ApplicationRecord
  has_many :carteira_ativos
  has_many :cotacaos

  enum tipo: {
      acao: 1,
      fii: 2,
      moeda: 3,
      fundo: 4,
      criptomoeda: 5,
      tesouro: 6
  }

  def nome_amigavel
    if descricao.blank?
      nome
    else
      "#{descricao} (#{nome})"
    end
  end

end
