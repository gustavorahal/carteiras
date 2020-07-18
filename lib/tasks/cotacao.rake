namespace :cotacao do

  def get_rapidapi_json(service_url, rapidapi_host)
    uri = URI(service_url)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(uri)
    request["x-rapidapi-host"] = rapidapi_host
    request["x-rapidapi-key"] = 'ENV.fetch("RAPIDAPI_KEY")'

    response = http.request(request)
    json_response = JSON.parse(response.read_body)
  end

  def get_preco_acao(ativo)
    # real time (ou quase isso)
    url = "https://apidojo-yahoo-finance-v1.p.rapidapi.com/market/get-quotes?region=US&lang=en&symbols=#{ativo}"
    api_host = 'apidojo-yahoo-finance-v1.p.rapidapi.com'
    json_response = get_rapidapi_json(url, api_host)
    json_response['quoteResponse']['result'][0]['regularMarketPrice']
  end


  namespace :atualiza do
    
    task acoes: :environment do
      Ativo.connection
      Ativo.all.each do |ativo|
        next unless ativo.tipo.in? ['acao','fii']

        ativo_str = ativo.nome
        if ativo.moeda == 'BRL'
          ativo_str = ativo_str + '.SA'
        end

        puts ativo_str
        preco = get_preco_acao(ativo_str).to_f
        puts "Preço: #{preco}"

        Cotacao.create(ativo_id: ativo.id, valor_unit: preco, data: DateTime.now())

      end
    end

    task tesouro: :environment do
      tesouro = {'Tesouro IPCA+ 2035' => 'https://taxas-tesouro.com/resgatar/tesouro-ipca+-2035/',
                 'Tesouro Selic 2025' => 'https://taxas-tesouro.com/resgatar/tesouro-selic-2025/',
                 'Tesouro IPCA+ com Juros Semestrais 2050' => 'https://taxas-tesouro.com/resgatar/tesouro-ipca+-com-juros-semestrais-2050/',
                 'Tesouro IPCA+ com Juros Semestrais 2055' => 'https://taxas-tesouro.com/resgatar/tesouro-ipca+-com-juros-semestrais-2055/'
      }

      tesouro.each do |titulo, url|
        document = Nokogiri::HTML.parse(open(url))
        tags = document.xpath("//span[@class='ml-1 sm:text-xl']")
        # conversão manual do formato pt_BR para en_US
        preco = tags[3].text.gsub('R$ ', '').gsub('.','').gsub(',', '.')
        data = tags[3].text.to_datetime
        puts titulo, preco, data
        ativo = Ativo.find_by_nome titulo
        Cotacao.create(ativo_id: ativo.id, valor_unit: preco, data: DateTime.now())
      end
    end

    task xp_dolar: :environment do
      url = 'https://institucional.xpi.com.br/investimentos/fundos-de-investimento/detalhes-de-fundos-de-investimento.aspx?F=2476'
      document = Nokogiri::HTML.parse(open(url))
      table = document.css('table').first
      preco = table.css('tr')[1].css('td')[1].text.strip().gsub(',', '.').to_f
      puts preco
      ativo = Ativo.find_by_nome 'VOTORANTIM FIC FI CAMBIAL DÓLAR'
      Cotacao.create(ativo_id: ativo.id, valor_unit: preco, data: DateTime.now())
    end

    task orama_ouro: :environment do
      url = 'https://data.anbima.com.br/fundos/318396'
      url = 'https://api.anbima.com.br/feed/fundos/v1/fundos/318396'

      require 'oauth2'
      client = OAuth2::Client.new('EXAMPLE_CLIENT_ID', 'EXAMPLE_CLIENT_SECRET', :site => 'https://api.anbima.com.br/oauth/access-token')

      client.auth_code.authorize_url(:redirect_uri => 'https://api.anbima.com.br/feed/fundos')

      token = client.auth_code.get_token('client_credentials', :redirect_uri => 'https://api.anbima.com.br/oauth/access-token',
                                         :headers => {'Authorization' => "Basic #{Base64.encode64('EXAMPLE_CLIENT_ID:EXAMPLE_CLIENT_SECRET')}"})
      response = token.get('/fundos/318396')
      response.class.name

    end

    task usdbrl: :environment do
      api_host = 'currency-converter5.p.rapidapi.com'

      url_usdbrl = "https://currency-converter5.p.rapidapi.com/currency/convert?format=json&from=USD&to=BRL&amount=1"
      json_response = get_rapidapi_json(url_usdbrl, api_host)
      preco = json_response['rates']['BRL']['rate'].to_f
      ativo = Ativo.find_by_nome 'CURRENCY:USDBRL'
      Cotacao.create(ativo_id: ativo.id, valor_unit: preco, data: DateTime.now())

      sleep(8) # api exige um tempo entre chamadas

      url_brlusd = "https://currency-converter5.p.rapidapi.com/currency/convert?format=json&from=BRL&to=USD&amount=1"
      json_response = get_rapidapi_json(url_brlusd, api_host)
      preco = json_response['rates']['USD']['rate'].to_f
      ativo = Ativo.find_by_nome 'CURRENCY:BRLUSD'
      Cotacao.create(ativo_id: ativo.id, valor_unit: preco, data: DateTime.now())
    end

    #task prov: :environment do
      # Operacao.all.each do |operacao|
      #   carteira_ativo = CarteiraAtivo.where(ativo_id: operacao.ativo_id,
      #                                        carteira_id: operacao.carteira_id).first
      #   operacao.carteira_ativo = carteira_ativo
      #   operacao.save
      # end
      #
      # Ativo.all.each do |ativo|
      #   next if CarteiraAtivo.exists?(ativo_id: ativo.id)
      #   CarteiraAtivo.create(carteira_id: 1, ativo_id: ativo.id, valido: false)
      #   CarteiraAtivo.create(carteira_id: 2, ativo_id: ativo.id, valido: false)
      # end
      #end

  end

end
