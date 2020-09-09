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
    url = 'https://institucional.xpi.com.br/investimentos/fundos-de-investimento/detalhes-de-fundos-de-investimento.aspx?F=2476'
    document = Nokogiri::HTML.parse(open(url))
    table = document.css('table').first
    preco = table.css('tr')[1].css('td')[1].text.strip.gsub(',', '.').to_f
    data_str = table.css('tr')[1].css('td')[0].text.strip
    data = Time.zone.parse(data_str).to_datetime

    [data, preco]
  end

  def self.usd_brl
    api_host = 'currency-converter5.p.rapidapi.com'
    url_usdbrl = "https://currency-converter5.p.rapidapi.com/currency/convert?format=json&from=USD&to=BRL&amount=1"
    json_response = fetch_rapidapi_json(url_usdbrl, api_host)
    json_response['rates']['BRL']['rate'].to_f
  end

  def self.brl_usd
    api_host = 'currency-converter5.p.rapidapi.com'
    url_brlusd = "https://currency-converter5.p.rapidapi.com/currency/convert?format=json&from=BRL&to=USD&amount=1"
    json_response = fetch_rapidapi_json(url_brlusd, api_host)
    json_response['rates']['USD']['rate'].to_f
  end

  def self.btc_brl
    url = "https://coingecko.p.rapidapi.com/simple/price?ids=BITCOIN&vs_currencies=BRL"
    api_host = 'coingecko.p.rapidapi.com'

    json_response = fetch_rapidapi_json(url, api_host)
    json_response['bitcoin']['brl']
  end

  # Real time (ou quase isso)
  def self.acao(ativo)
    url = "https://apidojo-yahoo-finance-v1.p.rapidapi.com/market/v2/get-quotes?region=US&lang=en&symbols=#{ativo}"
    api_host = 'apidojo-yahoo-finance-v1.p.rapidapi.com'
    json_response = fetch_rapidapi_json(url, api_host)

    result = json_response['quoteResponse']['result']
    result[0]['regularMarketPrice'] unless result.empty?
  end

  # def self.busca_fundo(nome_fundo)
  #   #url = 'https://data.anbima.com.br/fundos/318396'
  #   #url = 'https://api.anbima.com.br/feed/fundos/v1/fundos/318396'
  #   # ANBIMA
  #   client_id = 'EXAMPLE_CLIENT_ID'
  #   client_secret = 'EXAMPLE_CLIENT_SECRET'
  #   client = OAuth2::Client.new(client_id, client_secret,
  #                               site: 'http://api-sandbox.anbima.com.br',
  #                               authorize_url: '/oauth/access-token',
  #                               token_url: '/oauth/access-token')
  #
  #   token = client.client_credentials.get_token(redirect_uri: 'https://localhost:8080/oauth2/callback',
  #                          headers: {'Authorization' => "Basic #{Base64.encode64("#{client_id}:#{client_secret}")}"})
  #   response = token.get('/feed/fundos/v1/fundos?size=10',
  #                        headers: { 'client_id' => client_id,
  #                                   'access_token' => token.token},
  #                                    'accept' => 'application/json' )
  #   response.class.name
  # end


  def self.fetch_rapidapi_json(service_url, rapidapi_host)
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
