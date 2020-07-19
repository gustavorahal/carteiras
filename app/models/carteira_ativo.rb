class CarteiraAtivo < ApplicationRecord
  has_many :operacoes
  belongs_to :ativo
  belongs_to :carteira

  def data_montagem
    operacoes.where(mon_ou_des: 1).order(data: :desc).limit(1)[0].data
  end

  def nome_ativo
    ativo.nome_completo
  end

end
