class Ativo < ApplicationRecord
  has_many :cotacoes
  has_many :referencia_ativos

  before_save :checa_cnpj

  enum tipo: {
      acao: 1,
      fii: 2,
      moeda: 3,
      fundo: 4,
      criptomoeda: 5,
      tesouro: 6,
      etf: 7,
      debenture: 8,
      cra: 9
  }

  def nome_amigavel
    if tipo == 'fundo'
      "#{nome} (#{cnpj})"
    elsif descricao.blank?
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

  private

  # Se estamos manipulando um ativo tipo "fundo", é obrigatório
  # especificar um CNPJ porque esta informação é usada para buscar valor de cotas
  def checa_cnpj
    if tipo == 'fundo' && cnpj.blank?
      errors.add(:base, "Informação de CNPJ para fundo #{nome} faltando")
      throw :abort
    end
  end

end
