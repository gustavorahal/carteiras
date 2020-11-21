require 'open-uri' # para 'open' não conflitar com Kernel.open

class BuscaCotacao

  def self.tesouro(titulo)
    titulos = { 'Tesouro IPCA+ 2024' => 'https://taxas-tesouro.com/resgatar/tesouro-ipca+-2024/',
                'Tesouro IPCA+ 2035' => 'https://taxas-tesouro.com/resgatar/tesouro-ipca+-2035/',
                'Tesouro IPCA+ com Juros Semestrais 2026' => 'https://taxas-tesouro.com/resgatar/tesouro-ipca+-com-juros-semestrais-2026/',
                'Tesouro IPCA+ com Juros Semestrais 2050' => 'https://taxas-tesouro.com/resgatar/tesouro-ipca+-com-juros-semestrais-2050/',
                'Tesouro IPCA+ com Juros Semestrais 2055' => 'https://taxas-tesouro.com/resgatar/tesouro-ipca+-com-juros-semestrais-2055/',
                'Tesouro Prefixado 2023' => 'https://taxas-tesouro.com/resgatar/tesouro-prefixado-2023/',
                'Tesouro Prefixado 2025' => 'https://taxas-tesouro.com/resgatar/tesouro-prefixado-2025/',
                'Tesouro Prefixado com Juros Semestrais 2029' => 'https://taxas-tesouro.com/resgatar/tesouro-prefixado-com-juros-semestrais-2029/',
                'Tesouro Selic 2023' => 'https://taxas-tesouro.com/resgatar/tesouro-selic-2023/',
                'Tesouro Selic 2025' => 'https://taxas-tesouro.com/resgatar/tesouro-selic-2025/' }

    return unless titulo.in? titulos

    document = Nokogiri::HTML.parse(open(titulos[titulo]))
    tags = document.xpath("//span[@class='ml-1 sm:text-xl']")
    # conversão manual do formato pt_BR para en_US
    preco = tags[3].text.gsub('R$ ', '').gsub('.','').gsub(',', '.')
    data_str = tags[4].text
    data = Time.zone.parse(data_str).to_datetime

    [data, preco]
  end

  def self.fundo_xp_dolar
    # url da anbima https://data.anbima.com.br/fundos/072176
    url = 'https://institucional.xpi.com.br/investimentos/fundos-de-investimento/detalhes-de-fundos-de-investimento.aspx?F=2476'
    document = Nokogiri::HTML.parse(open(url))
    table = document.css('table').first
    preco = table.css('tr')[1].css('td')[1].text.strip.gsub(',', '.').to_f
    data_str = table.css('tr')[1].css('td')[0].text.strip
    data = Time.zone.parse(data_str).to_datetime

    [data, preco]
  end

  # Fonte: https://dadosabertos.bcb.gov.br/dataset/dolar-americano-usd-todos-os-boletins-diarios/resource/22ab054c-b3ff-4864-82f7-b2815c7a77ec?inner_span=True
  def self.usd_brl(data = Date.today)
    # formato de data esperado pela API: 11-19-2020 (MM-DD-AAAA)
    data_str = data.strftime('%m-%d-%Y')
    url = "https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata/CotacaoDolarDia(dataCotacao=@dataCotacao)?@dataCotacao='#{data_str}'&$top=100&$format=json"
    uri = URI(url)
    response = Net::HTTP.get(uri)
    json_response = JSON.parse(response)
    return nil if json_response['value'].empty?

    json_response['value'][0]['cotacaoCompra'].to_f
  end

  def self.brl_usd
    api_host = 'currency-converter5.p.rapidapi.com'
    url_brlusd = "https://currency-converter5.p.rapidapi.com/currency/convert?format=json&from=BRL&to=USD&amount=1"
    json_response = _fetch_rapidapi_json(url_brlusd, api_host)
    json_response['rates']['USD']['rate'].to_f
  end

  def self.btc_brl
    url = "https://coingecko.p.rapidapi.com/simple/price?ids=BITCOIN&vs_currencies=BRL"
    api_host = 'coingecko.p.rapidapi.com'

    json_response = _fetch_rapidapi_json(url, api_host)
    json_response['bitcoin']['brl']
  end

  # Real time (ou quase isso)
  #
  # @param ativo_nome: string com nome do ativo
  # @param data: Date object ou nil caso seja a cotacao atual
  # @return [Float] valor do ativo na data especificada
  def self.acao(ativo_nome, data, bolsa = nil)
    ativo_str = ativo_nome
    ativo_str += '.SA' if bolsa == 'BVMF'

    api_host = 'apidojo-yahoo-finance-v1.p.rapidapi.com'

    if data == Date.today || data.nil?
      url = "https://apidojo-yahoo-finance-v1.p.rapidapi.com/market/v2/get-quotes?region=US&lang=en&symbols=#{ativo_str}"
      json_response = _fetch_rapidapi_json(url, api_host)
      result = json_response['quoteResponse']['result']
      return result[0]['regularMarketPrice'].to_f unless result.empty?
    else
      from_data = data.to_time.to_i
      to_data = (data + 1.day).to_time.to_i
      url = "https://apidojo-yahoo-finance-v1.p.rapidapi.com/stock/get-histories?region=US&symbol=#{ativo_str}&from=#{from_data}&to=#{to_data}&events=div&interval=1d"
      json_response = _fetch_rapidapi_json(url, api_host)
      dado = json_response['chart']['result'][0]['indicators']['quote'][0]
      return nil if dado.empty?

      dado['close'][0].round(2).to_f
    end

  end


  private

  def self._fetch_rapidapi_json(service_url, rapidapi_host)
    uri = URI(service_url)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(uri)
    request["x-rapidapi-host"] = rapidapi_host
    request["x-rapidapi-key"] = 'ENV.fetch("RAPIDAPI_KEY")'

    response = http.request(request)
    JSON.parse(response.read_body)
  end

end
