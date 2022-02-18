require 'open-uri' # para 'open' não conflitar com Kernel.open
require 'net/http'

module BuscaCotacao
  class BolsaMarketstack < BolsaBase

    def self.ticker_fix(ticker, bolsa)
      # Tickers como BRK.B precisam ser convertidos para BRK-B
      ticker_fixed = ticker.gsub('.', '-')
      ticker_fixed += '.BVMF' if bolsa == 'BVMF'

      ticker_fixed
    end

    def self.busca(ticker, data, bolsa = nil)
      # Tickers como BRK.B precisam ser convertidos para BRK-B
      ticker_fixed = ticker_fix ticker, bolsa

      _get_quote ticker_fixed, data, bolsa
    end


    #
    # Private
    #

    def self._get_quote(ticker, data, bolsa = nil)
      access_key = ENV['MARKETSTACK_ACCESS_KEY']
      raise StandardError, "MARKETSTACK_ACCESS_KEY env var not set" if access_key.blank?

      data_str = data.strftime('%Y-%m-%d')

      url = "http://api.marketstack.com/v1/tickers/#{ticker}/eod/#{data_str}?access_key=#{access_key}"
      Rails.logger.info "BuscaBolsa: Chamando #{url}"
      uri = URI(url)
      json = Net::HTTP.get(uri)
      api_response = JSON.parse(json)

      return nil if api_response.blank?

      if api_response['error'].present?
        erro = api_response['error']['message']
        raise StandardError, "Erro buscando ticker #{ticker} em #{data}: #{erro}"
      end

      api_response['close']
    end

  end
end