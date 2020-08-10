class Cotacao < ApplicationRecord
  belongs_to :ativo

  def self.ultima_cotacao(ativo_id)
    where(ativo_id: ativo_id).order(data: :desc).limit(1).first
  end

  def self.cotacao_usdbrl
    Rails.cache.fetch 'cotacao_usdbrl', expires_in: 1.day do
      ultima_cotacao Ativo.find_by_nome('CURRENCY:USDBRL').id
    end
  end


end
