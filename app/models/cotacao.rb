class Cotacao < ApplicationRecord
  belongs_to :ativo

  def self.ultima_cotacao(ativo_id, moeda = 'BRL')
    where(ativo_id: ativo_id).order(data: :desc).limit(1).first
  end

end
