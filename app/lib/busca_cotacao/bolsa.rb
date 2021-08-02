require 'open-uri' # para 'open' não conflitar com Kernel.open

module BuscaCotacao
  class Bolsa

    # @return: [preco, fonte]
    def self.busca(ticker, bolsa, data)
      preco, fonte = _api_busca(ticker, data, bolsa)
      return [preco, fonte] unless preco.blank?

      nil
    end


    #
    # Privado
    #

    def self._api_busca(ticker, data, bolsa)
      preco = nil

      begin
        # As cotações do Market Stack são mais corretas do que as que
        # Yahoo puxa muitas vezes. Porém Yahoo é mais completo de dados.
        preco = _api_marketstack(ticker, data, bolsa)
      rescue StandardError => e
        Rails.logger.info("BuscaAtivos::Bolsa._api_busca: #{e.message}")
      end

      return [preco, 'marketstack'] unless preco.nil?

      begin
        preco = _api_yahoo_finance(ticker, data, bolsa)
      rescue StandardError => e
        Rails.logger.info("BuscaAtivos::Bolsa._api_busca: #{e.message}")
      end

      [preco, 'yahoo_finance_rapidapi']
    end

    def self._api_marketstack(ticker, data, bolsa = nil)
      # Tickers como BRK.B precisam ser convertidos para BRK-B
      ticker = ticker.gsub('.', '-')
      ticker += '.BVMF' if bolsa == 'BVMF'

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

    # Real time (ou quase isso) -- OLD API YAHOO FINANCE
    #
    # @param ticker: string com nome do ativo
    # @param data: Date object ou nil caso seja a cotacao atual
    # @return [Float] valor do ativo na data especificada
    def self._api_yahoo_finance(ticker, data, bolsa = nil)
      ticker_str = ticker
      # Tickers como BRK.B precisam ser convertidos para BRK-B
      ticker_str = ticker_str.gsub('.', '-')
      ticker_str += '.SA' if bolsa == 'BVMF'

      api_host = 'apidojo-yahoo-finance-v1.p.rapidapi.com'

      if data == Date.today || data.nil?
        url = "https://apidojo-yahoo-finance-v1.p.rapidapi.com/market/v2/get-quotes?region=US&lang=en&symbols=#{ticker_str}"
        json_response = Utils.fetch_rapidapi_json(url, api_host)
        result = json_response['quoteResponse']['result']
        return result[0]['regularMarketPrice'].to_f unless result.empty?
      else
        from_data = data.to_time.to_i
        to_data = (data + 1.day).to_time.to_i
        url = "https://apidojo-yahoo-finance-v1.p.rapidapi.com/stock/get-histories?region=US&symbol=#{ticker_str}&from=#{from_data}&to=#{to_data}&events=div&interval=1d"
        Rails.logger.info "BuscaBolsa: Chamando #{url}"
        json_response = Utils.fetch_rapidapi_json(url, api_host)
        if json_response['chart']['result'].nil?
          raise StandardError, "Yahoo API: Não foi possivel obter cotação de #{ticker_str}: #{json_response['chart']['error']['description']}"
        end
        dado = json_response['chart']['result'][0]['indicators']['quote'][0]
        return nil if dado.empty?

        dado['close'][0].round(2).to_f
      end

    end

  end
end