require 'open-uri' # para 'open' não conflitar com Kernel.open

class BuscaBolsa

  def self.busca(ativo, data)

    bolsa = ('BVMF' if ativo.moeda == 'BRL')
    data_efetiva = data
    preco = _api_busca(ativo.nome, data_efetiva, bolsa)
    # infelizmente nossa API é cheia de furos, com informações não disponíveis para determinadas datas
    tentativas = 3
    while preco.blank?
      if tentativas.zero?
        Rails.logger.info("Desistindo de tentar, pegando última cotacao para #{ativo.nome}")
        return Cotacao.where(ativo_id: ativo.id).last
      end
      data_efetiva = Utils.ajusta_data(data_efetiva - 1.day, ativo)
      preco = _api_busca(ativo.nome, data_efetiva, bolsa)
      Rails.logger.info("Tentando nova cotação para #{ativo.nome} na data #{data_efetiva}")
      tentativas -= 1
    end

    [data_efetiva, preco]
  end


  #
  # Privado
  #

  def self._api_busca(ticker, data, bolsa)
    begin
      preco = _api_marketstack(ticker, data, bolsa)
    rescue StandardError
      preco = _api_yahoo_finance(ticker, data, bolsa)
    end

    if preco.nil?
      preco = _api_yahoo_finance(ticker, data, bolsa)
    end

    preco
  end

  def self._api_marketstack(ticker, data, bolsa = nil)

    # Tickers como BRK.B precisam ser convertidos para BRK-B
    ticker = ticker.gsub('.', '-')
    ticker += '.BVMF' if bolsa == 'BVMF'

    access_key = ENV['MARKETSTACK_ACCESS_KEY']
    data_str = data.strftime('%Y-%m-%d')

    url = "http://api.marketstack.com/v1/tickers/#{ticker}/eod/#{data_str}?access_key=#{access_key}"
    Rails.logger.info "BuscaCotacao.acao_marketstack: Chamando #{url}"
    uri = URI(url)
    json = Net::HTTP.get(uri)
    api_response = JSON.parse(json)

    return nil if api_response.blank?

    raise StandardError, api_response['error']['message'] if api_response['error'].present?

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
      json_response =  Utils.fetch_rapidapi_json(url, api_host)
      result = json_response['quoteResponse']['result']
      return result[0]['regularMarketPrice'].to_f unless result.empty?
    else
      from_data = data.to_time.to_i
      to_data = (data + 1.day).to_time.to_i
      url = "https://apidojo-yahoo-finance-v1.p.rapidapi.com/stock/get-histories?region=US&symbol=#{ticker_str}&from=#{from_data}&to=#{to_data}&events=div&interval=1d"
      Rails.logger.info "BuscaCotacao.acao_yahoo_finance: Chamando #{url}"
      json_response =  Utils.fetch_rapidapi_json(url, api_host)
      if json_response['chart']['result'].nil?
        raise StandardError, "Yahoo API: Não foi possivel obter cotação de #{ticker_str}: #{json_response['chart']['error']['description']}"
      end
      dado = json_response['chart']['result'][0]['indicators']['quote'][0]
      return nil if dado.empty?

      dado['close'][0].round(2).to_f
    end

  end

end