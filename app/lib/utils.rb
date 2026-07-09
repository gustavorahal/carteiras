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
  #
  # @param data: uma data qualquer a partir da qual será calculado a lista
  def self.ultimos_meses(data)
    current_date = data.months_ago(1).end_of_month
    date_range = []
    6.times do
      date_range.push current_date
      current_date = current_date.months_ago(1).end_of_month
    end

    date_range.reverse
  end


  def self.fetch_rapidapi_json(url, rapidapi_host)
    uri = URI(url)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.open_timeout = 5
    http.read_timeout = 10

    request = Net::HTTP::Get.new(uri)
    request['x-rapidapi-host'] = rapidapi_host
    request['x-rapidapi-key'] = ENV.fetch("RAPIDAPI_KEY")

    response = http.request(request)
    unless response.code.to_i.between?(200, 299)
      raise StandardError, "RapidAPI request failed with HTTP #{response.code}: #{response.message}"
    end

    JSON.parse(response.body) if response.body.present?
  end

end
