class Cotacao < ApplicationRecord
  belongs_to :ativo

  # Cotação de um ativo
  #
  # @param data: considera a cotação mais próxima da data especificada
  def self.cotacao_ativo(ativo_id, data: Date.today)
    data_str = data.strftime '%F'
    Rails.cache.fetch("cotacao_ativo_#{ativo_id}", expires_in: 5.seconds) do
      where(ativo_id: ativo_id)
          .where("data <= '#{data_str}'")
          .order(data: :desc)
          .limit(1).first
    end
  end

  # @param data: considera a cotação mais próxima da data especificada
  def self.cotacao_usdbrl(data: Date.today)
    Rails.cache.fetch('cotacao_usdbrl', expires_in: 5.seconds) do
      cotacao_ativo Ativo.find_by_nome('CURRENCY:USDBRL').id, data: data
    end
  end

  # @param data: considera a cotação mais próxima da data especificada
  def self.cotacao_brlusd(data: Date.today)
    Rails.cache.fetch('cotacao_brlusd', expires_in: 5.seconds) do
      cotacao_ativo Ativo.find_by_nome('CURRENCY:BRLUSD').id, data: data
    end
  end

  def valor_unit_moeda(moeda: 'BRL')
    Rails.cache.fetch("valor_unit_#{moeda}_#{id}", expires_in: 5.seconds) do
      if moeda == ativo.moeda
        valor_unit
      elsif moeda == 'BRL' # e ativo é USD
        valor_unit * Cotacao.cotacao_usdbrl.valor_unit
      elsif moeda == 'USD' # e ativo é BRL
        valor_unit * Cotacao.cotacao_brlusd.valor_unit
      end
    end
  end

end
