require 'open-uri' # para 'open' não conflitar com Kernel.open
require 'net/http'

module BuscaCotacao
  class BolsaYfinance < BolsaBase

    @@api_host = 'yh-finance.p.rapidapi.com'

    def self.ticker_fix(ticker, bolsa)
      # Tickers como BRK.B precisam ser convertidos para BRK-B
      ticker_fixed = ticker.gsub('.', '-')
      ticker_fixed += '.SA' if bolsa == 'BVMF'

      ticker_fixed
    end

    def self.busca(ticker, data, bolsa = nil)
      ticker_fixed = ticker_fix ticker, bolsa

      if data == Date.today || data.nil?
        return _get_quote(ticker_fixed)
      else
        return _get_historical_data(ticker_fixed, data)
      end

    end

    #
    # Private
    #

    def self._get_quote(ticker)
      url = "https://#{@@api_host}/market/v2/get-quotes?region=US&lang=en&symbols=#{ticker}"
      Rails.logger.info "BuscaBolsa: Chamando #{url}"
      json_response = Utils.fetch_rapidapi_json(url, @@api_host)
      result = json_response['quoteResponse']['result']
      return result[0]['regularMarketPrice'].to_f unless result.empty?
    end

    def self._get_historical_data(ticker, data)
      url = "https://#{@@api_host}/stock/v3/get-historical-data?symbol=#{ticker}"
      Rails.logger.info "BuscaBolsa: Chamando #{url}"
      json_response = Utils.fetch_rapidapi_json(url, @@api_host)
      return unless json_response

      json_response["prices"].each do |price|
        data_price = Time.at(price["date"]).to_date
        if data_price == data
          return price["close"]
        end
      end

      nil
    end

  end
end