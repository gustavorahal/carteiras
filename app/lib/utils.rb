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

  # Retorna o ultimo dia util, excluindo hoje (se for o caso)
  # Ou seja, se hoje for dia util, retorna ontem (ou o ultimo dia util)
  # Ex. Hoje "Segunda", retorna "Sexta"
  def self.ultimo_dia_util(data)
    data_ajustada = data
    data_ajustada -= 1.day until Utils.dia_util?(data_ajustada)
    # Vamos excluir o dia de hoje caso seja dia util porque queremos o ultimo dia
    data_ajustada = ultimo_dia_util(data_ajustada - 1.day) if data == Date.today && Utils.dia_util?(data) && data_ajustada == data
    data_ajustada
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