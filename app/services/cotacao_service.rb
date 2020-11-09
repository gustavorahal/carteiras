class CotacaoService



  # param @ativo ActiceRecord Ativo
  def self.cotacao(ativo, data)
    Rails.cache.fetch("cotacao_ativo_#{ativo.id}", expires_in: 3.seconds) do
      data_cotacao = _ajusta_data(data)

      cotacao = Cotacao.where(ativo_id: ativo.id, data: data_cotacao).first
      return cotacao if cotacao

      Rails.logger.debug "Buscando cotação para #{ativo.nome} na data #{data_cotacao}"
      case ativo.tipo
      when 'acao', 'fii'
        return _busca_e_registra_acao(ativo, data_cotacao)
      when 'moeda'
        return _busca_e_registra_moeda(ativo, data_cotacao)
      when 'criptomoeda'
        return _busca_e_registra_moeda(ativo, data_cotacao)
      when 'tesouro'
        return _busca_e_registra_tesouro(ativo, data_cotacao)
      when 'fundo'
        # como não temos um jeito automatizado de buscar fundos
        # retornar ultima cotação
        return Cotacao.where(ativo_id: ativo.id).order(data: :desc).first
      else
        raise StandardError, 'Tipo de ativo não suportado para busca de cotação'
      end
    end
  end

  def self.cotacao_usdbrl(data)
    Rails.cache.fetch("cotacao_usdbrl_#{data}", expires_in: 3.seconds) do
      cotacao(Ativo.find_by_nome('CURRENCY:USDBRL'), data)
    end
  end

  def self.cotacao_brlusd(data)
    Rails.cache.fetch("cotacao_brlusd_#{data}", expires_in: 3.seconds) do
      cotacao(Ativo.find_by_nome('CURRENCY:BRLUSD'), data)
    end
  end

  def self.busca_e_registra_tudo(data = Date.today)
    Ativo.all.each do |ativo|
      cotacao(ativo, data)
    end
  end


  #
  # Métodos privados
  #

  # @return Objeto data, considerando fatores como final de semana,
  # feriado e fechamento de pregão
  def self._ajusta_data(data)

    data_ajustada = data
    # Considerar finais de semana
    data_ajustada = data_ajustada.prev_weekday if data_ajustada.on_weekend?

    # E feriados
    data_ajustada = data_ajustada.prev_weekday if Holidays.on(data_ajustada, :br).present?

    # Se estamos no horário do pregão, pegar cotação do dia anterior
    # Só queremos armazenar a cotação de fechamento do dia
    # Usar "zone" porque estou pensando em termos de hora do Brasil, que
    # é o config do Rails também
    data_ajustada = if Time.zone.now.hour < 19
                      data_ajustada - 1.day
                    else
                      data_ajustada
                    end

    data_ajustada
  end

  # @return Cotacao ActiveRecord object
  def self._busca_e_registra_moeda(ativo, data)
    preco = if ativo.nome == 'CURRENCY:BRLUSD'
              BuscaCotacao.brl_usd
            elsif ativo.nome == 'CURRENCY:USDBRL'
              BuscaCotacao.usd_brl
            elsif ativo.nome == 'CURRENCY:BTCBRL'
              BuscaCotacao.btc_brl
            else
              nil
            end
    return if preco.nil?

    Cotacao.create!(ativo_id: ativo.id, valor_unit: preco, data: data)
  end

  # @return Cotacao ActiveRecord object
  def self._busca_e_registra_tesouro(ativo, data)
    data_api, preco = BuscaCotacao.tesouro ativo.nome
    # Ignoramos a data_api e consideramos a data fornecida porque
    # a api sempre vai no fornecer a ultima data disponivel
    Cotacao.create!(ativo_id: ativo.id, valor_unit: preco, data: data)
  end

  # @return Cotacao ActiveRecord object
  def self._busca_e_registra_acao(ativo, data)
    bolsa = ('BVMF' if ativo.moeda == 'BRL')
    data_efetiva = data
    preco = BuscaCotacao.acao(ativo.nome, data_efetiva, bolsa)
    # infelizmente nossa API é cheia de furos, com informações não disponíveis para determinadas datas
    tentativas = 3
    while preco.blank?
      if tentativas.zero?
        Rails.logger.debug("Desistindo de tentar, pegando última cotacao para #{ativo.nome}")
        return Cotacao.where(ativo_id: ativo.id).last
      end
      data_efetiva = _ajusta_data(data_efetiva - 1.day)
      preco = BuscaCotacao.acao(ativo.nome, data_efetiva, bolsa)
      Rails.logger.debug("Tentando nova cotação para #{ativo.nome} na data #{data_efetiva}")
      tentativas -= 1
    end

    # Como podemos ter escolhido uma data diferente da fornecida, ver se já não temos ela afinal
    # antes de tentar criar
    Cotacao.find_or_create_by!(ativo_id: ativo.id, valor_unit: preco, data: data_efetiva)
  end

end
