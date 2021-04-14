require 'open-uri' # para 'open' não conflitar com Kernel.open

module BuscaCotacao
  class Moeda

    def self.busca(ativo, data)
      if ativo.id == Ativo.find_by_nome('BRLUSD').id
        _brl_usd
      elsif ativo.id == Ativo.find_by_nome('USDBRL').id
        _usd_brl(data)
      elsif ativo.id == Ativo.find_by_nome('BTCBRL').id
        _btc_brl
      else
        raise StandardError, "Tipo de moeda #{ativo.tipo} ativo ID #{ativo.id} não suportado para busca de cotação"
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

      json_response['value'][0]['cotacaoCompra'].to_f
    end

    def self._brl_usd
      api_host = 'currency-converter5.p.rapidapi.com'
      url = 'https://currency-converter5.p.rapidapi.com/currency/convert?format=json&from=BRL&to=USD&amount=1'
      Rails.logger.info "BuscaCotacao.brl_usd: Chamando #{url}"
      json_response = Utils.fetch_rapidapi_json(url, api_host)
      json_response['rates']['USD']['rate'].to_f
    end

    def self._btc_brl
      url = 'https://coingecko.p.rapidapi.com/simple/price?ids=BITCOIN&vs_currencies=BRL'
      Rails.logger.info "BuscaCotacao.btc_brl: Chamando #{url}"
      api_host = 'coingecko.p.rapidapi.com'

      json_response = Utils.fetch_rapidapi_json(url, api_host)
      json_response['bitcoin']['brl']
    end
  end
end