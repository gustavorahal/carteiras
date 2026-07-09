class CotacaoService

  # param @ativo: ActiceRecord Ativo
  # param @data: irá tentar buscar cotacao para data dada. Se não for possivel, retornar
  #              ultimo dia antes da data com uma cotacao disponivel
  def self.cotacao(ativo, data)
    CacheService.fetch_cotacao(ativo, data) do
      _resolve_cotacao(ativo, data)
    end
  end

  def self.moedas(de_para, data)
    raise "Cotação moeda #{de_para} não suportada" unless de_para.in? %w{USDBRL BRLUSD BTCBRL}

    cotacao(Ativo.find_by(nome: de_para), data)
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
  # @return [Cotacao]
  def self._resolve_cotacao(ativo, data)
    data_ajustada = _ajusta_data(data, ativo.tipo)
    if data_ajustada != data
      Rails.logger.info "Cotação para #{ativo.nome}: data ajustada de #{data} para #{data_ajustada}"
    end

    # 1a tentativa: Tenho uma cotação no BD? Se sim, retorne-a
    cotacao = Cotacao.find_by(ativo: ativo, data: data_ajustada)
    if cotacao.present?
      Rails.logger.info "Cotação para #{ativo.nome} em #{data_ajustada} disponivel no BD, retornando"
      return cotacao
    end

    # 2a tentativa: Busca cotação utilizando API de bolsa
    Rails.logger.info "Cotação para #{ativo.nome} em #{data_ajustada} NÃO disponivel no BD, vamos buscar"
    if Config.busca_cotacao_enabled?(ativo.tipo)
      cotacao = send("_busca_e_registra_#{ativo.tipo.downcase}", ativo, data_ajustada)
      if cotacao.present?
        Rails.logger.info "Cotação para #{ativo.nome} em #{data_ajustada} encontrada pelo backend/API, retornando"
        return cotacao
      end
    else
      Rails.logger.info "Cotação para #{ativo.nome} em #{data_ajustada}: busca cotação está desabilitada para #{ativo.tipo}"
    end


    # 3a tentativa: não encontrei na API, retornar a última cotação disponível
    unless cotacao
      cotacao = Cotacao.where(ativo: ativo).where('data <= ?', data).order(data: :desc).first
      if cotacao
        Rails.logger.info("Cotação para #{ativo.nome} em #{data_ajustada} NÃO disponível de nenhuma forma, pegando última cotação disponível no BD em #{cotacao.data}")
      else
        Rails.logger.info("Cotação para #{ativo.nome} em #{data_ajustada} NÃO disponível de nenhuma forma e sem cotação anterior no BD")
      end
    end

    cotacao
  end

  # Ajusta data considerando de tipo de ativo
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

  # @return Cotacao ActiveRecord object
  def self._busca_e_registra_fundo(ativo, data)
    resultado = BuscaCotacao::Facade.fundo(ativo.cnpj, data)
    if resultado
      Cotacao.find_or_create_by!(ativo: ativo,
                                 valor_unit: resultado.preco,
                                 data: resultado.data,
                                 fonte: resultado.fonte)
    end

    nil
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

    nil
  end

  # @return Cotacao ActiveRecord object
  def self._busca_e_registra_criptomoeda(ativo, data)
    _busca_e_registra_moeda(ativo, data)
  end

  # @return Cotacao ActiveRecord object
  def self._busca_e_registra_moeda(ativo, data)
    resultado = BuscaCotacao::Facade.moeda(ativo.nome, data)
    if resultado
      Cotacao.find_or_create_by!(ativo: ativo,
                                 valor_unit: resultado.preco,
                                 data: resultado.data,
                                 fonte: resultado.fonte)
    end
  end

  # @return Cotacao ActiveRecord object
  def self._busca_e_registra_bolsa(ativo, data)
    resultado = BuscaCotacao::Facade.bolsa(ativo.nome, ativo.moeda_negociacao, data)
    if resultado
      Cotacao.find_or_create_by!(ativo: ativo,
                                 valor_unit: resultado.preco,
                                 data: resultado.data,
                                 fonte: resultado.fonte)
    end

    nil
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
    # retorna nil e deixa pegar ultima cotação
    nil
  end

  def self._busca_e_registra_cdb(ativo, data)
    # como não temos um jeito automatizado de buscar cdb
    # retornar ultima cotação
    _busca_e_registra_cra(ativo, data)
  end

  def self._busca_e_registra_debenture(ativo, data)
    # como não temos um jeito automatizado de buscar cra ou debenture
    # retornar ultima cotação
    _busca_e_registra_cra(ativo, data)
  end

end
