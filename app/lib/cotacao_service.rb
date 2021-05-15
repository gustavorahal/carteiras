class CotacaoService

  # param @ativo: ActiceRecord Ativo
  # param @data: irá tentar buscar cotacao para data dada. Se não for possivel, retornar
  #              ultimo dia antes da data com uma cotacao disponivel
  def self.cotacao(ativo, data)
    # Porque expirar o cache para dado ativo em determinada data já que é algo que não mudaria?
    # R. Se pedirmos um cotacao para um ativo "hoje", vamos receber a cotacao de ontem ou anteontem
    # porque nosso backend só tem dados com mais de 1 dia de atraso.
    # Passados alguns dias, se pedirmos a cotacao para o mesmo ativo na mesma data, iriamos receber
    # a cotacao correta, do dia exato pedido. Nesse sentido, não podemos gravar o cache indefinidamente.
    # A cotacao de "hoje" esta bom para hoje, passado um tempo, queremos a cotacao correta, ou seja
    # da data efetivamente pedida.
    Rails.cache.fetch("cotacao_ativo_ID#{ativo.id}_#{data}", expires: 12.hours) do
      _resolve_cotacao(ativo, data)
    end
  end

  def self.cotacao_usdbrl(data)
    cotacao(Ativo.find_by_nome('USDBRL'), data)
  end

  def self.cotacao_brlusd(data)
    cotacao(Ativo.find_by_nome('BRLUSD'), data)
  end

  # Conseguimos obter cotação para ativo especificado?
  def self.ativo_suportado?(nome, moeda, tipo)
    raise "Tipo de ativo inválido" unless tipo.in? Ativo.tipos.keys

    if tipo.in? Ativo.tipos_bolsa
      BuscaCotacao::Facade.bolsa(nome, moeda, _ajusta_data(Date.today, tipo)) ? true : false
    else
      # por hora só checa bolsa
      true
    end
  end

  # Buscar cotação de todos ativos presentes nas diferentes carteiras
  # Útil para rodar diariamente e proativamente já buscar e registrar as
  # cotações
  def self.busca_e_registra_tudo(data)
    # Mesmo que os ativos se repitam nas carteiras, a primeira
    # vez que ele vai aparecer vai acontecer a busca pela cotacao
    # e nas subsequente vezes, vai encontrar no banco e não buscar mais.
    Carteira.all.each do |carteira|
      # No interessa saber quais os ativos 'hoje' presentes
      # nas carteiras e a partir deles, dai sim buscar suas
      # cotações na data informada
      ca = Posicao.new(carteira, Date.today)
      ca.ativos.each { |ativo| cotacao(ativo, data) }
    end
  end


  #
  # Métodos privados
  #

  # Encontra uma cotacão mais adequada de acordo com a data informada
  def self._resolve_cotacao(ativo, data)
    data_ajustada = _ajusta_data(data, ativo.tipo)
    if data_ajustada != data
      Rails.logger.info "Cotação para #{ativo.nome}: data ajustada de #{data} para #{data_ajustada}"
    end

    cotacao = Cotacao.find_by(ativo: ativo, data: data_ajustada)
    if cotacao.present?
      Rails.logger.info "Cotação para #{ativo.nome} em #{data_ajustada} disponivel no BD, retornando"
      return cotacao
    end

    Rails.logger.info "Cotação para #{ativo.nome} em #{data_ajustada} NÃO disponivel no BD, vamos buscar"
    send("_busca_e_registra_#{ativo.tipo.downcase}", ativo, data_ajustada)
  end

  # Ajusta data considerando de acordo com tipo de ativo
  #
  # Esta função precisa ter conhecimento das caracteristicas de cada ativo assim como do backend
  # Consider também fatores como final de semana, feriado, fechamento de pregão e tipo de ativo
  #
  # @return Objeto data
  def self._ajusta_data(data, tipo_ativo)
    raise "Tipo de ativo inválido" unless tipo_ativo.in? Ativo.tipos.keys

    data_ajustada = data
    # Caso passem data no futuro, ajeitar
    data_ajustada = Date.today if data > Date.today
    # vamos buscar o ultimo dia útil, excluindo hoje (caso seja um dia util)
    data_ajustada = Utils.ultimo_dia_util(data_ajustada)
    # tesouro tem um atraso de 2 dias uteis para atualizar cotas
    if tipo_ativo == 'tesouro' && data == Date.today
      data_ajustada = Utils.ultimo_dia_util(data_ajustada - 2.days)
    end

    # tesouro não negocia no ultimo dia do ano, mesmo que seja no meio da semana
    if tipo_ativo == 'tesouro' && data_ajustada == Date.new(data.year, 12, 31)
      data_ajustada -= 1.days
    end

    # fundos tem um atraso de 3 dias uteis para atualizar cotas
    if tipo_ativo == 'fundo' && data == Date.today
      data_ajustada = Utils.ultimo_dia_util(data_ajustada - 3.days)
    end

    data_ajustada
  end

  # Pela maneira como o Backend funciona, esta função faz algo
  # atipico. Aproveitando que a busca é custosa (download de arquivo de 30MB+)
  # e retorna informações de todos os fundos, vamos aproveitar e atualizar
  # informações de todos os fundos mas retornar só o que foi pedido
  #
  # @return Cotacao ActiveRecord object
  def self._busca_e_registra_fundo(ativo, data)
    cnpjs = Ativo.where(tipo: 'fundo').pluck(:cnpj)
    dados = BuscaCotacao::Fundos.busca(cnpjs, data.year, data.month)
    dados.each do |cnpj, vl_cotas|
      vl_cotas.each do |vl_cota|
        ativo = Ativo.find_by(cnpj: cnpj)
        data = vl_cota[0].to_date
        unless Cotacao.find_by(ativo: ativo, data: data)
          Cotacao.create!(ativo: ativo, data: data, valor_unit: vl_cota[1], fonte: 'cvm_gov')
        end
      end
    end

    Cotacao.find_by(ativo: ativo, data: data)
  end

  #
  #
  # @return Cotacao ActiveRecord object
  def self._busca_e_registra_tesouro(ativo, data)
    resultado = BuscaCotacao::Facade.tesouro(ativo.nome, data)
    if resultado
      Cotacao.find_or_create_by!(ativo: ativo,
                                 valor_unit: resultado.preco,
                                 data: resultado.data,
                                 fonte: resultado.fonte)
    end
  end

  # @return Cotacao ActiveRecord object
  def self._busca_e_registra_criptomoeda(ativo, data)
    _busca_e_registra_moeda(ativo, data)
  end

  # @return Cotacao ActiveRecord object
  def self._busca_e_registra_moeda(ativo, data)
    preco, fonte = BuscaCotacao::Moeda.busca(ativo.nome, data)
    Cotacao.create!(ativo_id: ativo.id, valor_unit: preco, data: data, fonte: fonte)
  end

  # @return Cotacao ActiveRecord object
  def self._busca_e_registra_bolsa(ativo, data)
    resultado = BuscaCotacao::Facade.bolsa(ativo.nome, ativo.moeda, data)
    if resultado
      Cotacao.find_or_create_by!(ativo: ativo,
                                 valor_unit: resultado.preco,
                                 data: resultado.data,
                                 fonte: resultado.fonte)
    else
      Rails.logger.info("Cotação para #{ativo.nome}: não encontrei preço em #{resultado.data}, pegando última cotação")
      Cotacao.where(ativo_id: ativo.id).last
    end
  end

  def self._busca_e_registra_fii(ativo, data)
    _busca_e_registra_bolsa(ativo, data)
  end

  def self._busca_e_registra_etf(ativo, data)
    _busca_e_registra_bolsa(ativo, data)
  end

  def self._busca_e_registra_acao(ativo, data)
    _busca_e_registra_bolsa(ativo, data)
  end

  def self._busca_e_registra_cra(ativo, data)
    # como não temos um jeito automatizado de buscar cra ou debenture
    # retornar ultima cotação
    Cotacao.where(ativo: ativo).order(data: :desc).first
  end

  def self._busca_e_registra_debenture(ativo, data)
    # como não temos um jeito automatizado de buscar cra ou debenture
    # retornar ultima cotação
    _busca_e_registra_cra(ativo, data)
  end

end
