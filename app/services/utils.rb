class Utils

  # Desdobramento de ação, ou seja, em quantas vezes ela foi reduzida
  #
  # @param n_vezes: dividir o valor da ação em quantas vezes?
  def self.desdobrar_acao(ativo, n_vezes)
    Operacao.where(ativo: ativo).each do |op|
      op.valor_unit = op.valor_unit / n_vezes
      op.quantidade = op.quantidade * n_vezes
      obs = "Desdobramento em #{n_vezes}x em #{Date.today}"
      op.observacao = op.observacao.nil? ? obs : op.observacao + '<br>' + obs
      op.save
    end
  end

  # Ajusta data considerando ultimo dia de pregão
  #
  # Se estamos no horário do pregão, pegar cotação do dia anterior.
  # Só queremos armazenar a cotação de fechamento do dia.
  # Atualmente considera-se 22h GMT como um horário em que todos pregões
  # que importam já encerraram.
  #
  # @return Objeto data, considerando fatores como final de semana,
  # feriado, fechamento de pregão e tipo de ativo
  def self.ajusta_data(data, ativo)
    data_ajustada = data
    data_ajustada -= 1.day if data == Date.today && dia_util?(data) && Time.now.hour < 22
    data_ajustada -= 1.day until dia_util?(data_ajustada)
    # fundos tem um atraso de 3 dias uteis para atualizar cotas
    data_ajustada -= 3.days if ativo.tipo == 'fundo' && data == Date.today
    
    data_ajustada
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