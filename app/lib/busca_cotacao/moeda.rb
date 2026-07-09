require 'open-uri' # para 'open' não conflitar com Kernel.open
require 'net/http'

module BuscaCotacao
  class Moeda

    # @return tupla [preco, fonte]. Exemplo: [5.5744, "bcb_gov"]
    def self.busca(de_para, data)
      if de_para == 'BRLUSD'
        _brl_usd
      elsif de_para == 'USDBRL'
        _usd_brl(data)
      elsif de_para == 'BTCBRL'
        _btc_brl
      else
        raise "Conversão de #{de_para} não suportado para busca de cotação"
      end
    end


    #
    # Privado
    #

    # Fonte: https://dadosabertos.bcb.gov.br/dataset/dolar-americano-usd-todos-os-boletins-diarios/resource/22ab054c-b3ff-4864-82f7-b2815c7a77ec?inner_span=True
    def self._usd_brl(data = Date.today)
      # formato de data esperado pela API: 11-19-2020 (MM-DD-AAAA)
      data_str = data.strftime('%m-%d-%Y')
      url = "https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata/CotacaoDolarDia(dataCotacao=@dataCotacao)?@dataCotacao='#{data_str}'&$top=100&$format=json"
      Rails.logger.info "BuscaCotacao.usd_brl: Chamando #{url}"
      uri = URI(url)
      response = Net::HTTP.get(uri)
      json_response = JSON.parse(response)
      return nil if json_response['value'].empty?

      [Utils.decimal(json_response['value'][0]['cotacaoCompra']), 'bcb_gov']
    end

    def self._brl_usd
      api_host = 'currency-converter5.p.rapidapi.com'
      url = 'https://currency-converter5.p.rapidapi.com/currency/convert?format=json&from=BRL&to=USD&amount=1'
      Rails.logger.info "BuscaCotacao.brl_usd: Chamando #{url}"
      json_response = Utils.fetch_rapidapi_json(url, api_host)
      [Utils.decimal(json_response['rates']['USD']['rate']), 'currency_converter_rapidapi']
    end

    def self._btc_brl
      url = 'https://coingecko.p.rapidapi.com/simple/price?ids=BITCOIN&vs_currencies=BRL'
      Rails.logger.info "BuscaCotacao.btc_brl: Chamando #{url}"
      api_host = 'coingecko.p.rapidapi.com'

      json_response = Utils.fetch_rapidapi_json(url, api_host)
      [Utils.decimal(json_response['bitcoin']['brl']), 'coingecko_rapidapi']
    end
  end
end
