class Utils

  def self.transferencia_de_custodia(carteira, ativo, nova_corretora)
    Operacao.create!(carteira: carteira, ativo: ativo, data: Date.today, quantidade: 0,
                     valor_unit: 0, operacao: 'C',
                     corretora: nova_corretora, operacao_sys: true,
                     observacao: "Transferência de custódia para #{nova_corretora.nome}")
  end

  def self.dia_util?(data)
    !data.on_weekend? && !Holidays.on(data, :br).present?
  end

  # Retorna uma lista com as datas do ultimo dia dos ultimos meses
  # do ano especificado
  #
  # @param data: uma data qualquer a partir da qual será calculado a lista
  def self.meses_passados_ano(data)
    lista = []
    (1..data.month - 1).each do |mes_num|
      lista.push Date.new(data.year, mes_num).end_of_month
    end

    lista
  end


  def self.fetch_rapidapi_json(service_url, rapidapi_host)
    uri = URI(service_url)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(uri)
    request['x-rapidapi-host'] = rapidapi_host
    request['x-rapidapi-key'] = 'ENV.fetch("RAPIDAPI_KEY")'

    response = http.request(request)
    JSON.parse(response.read_body)
  end

end