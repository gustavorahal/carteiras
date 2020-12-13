class CotacaoService

  # param @ativo ActiceRecord Ativo
  def self.cotacao(ativo, data)
    Rails.cache.fetch("cotacao_ativo_#{ativo.id}_#{data}", expires_in: 3.seconds) do
      data_cotacao = Utils.ajusta_data(data)

      cotacao = Cotacao.where(ativo: ativo, data: data_cotacao).order(data: :desc).first
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
    cotacao(Moedas.config.ativo_usdbrl, data)
  end

  def self.cotacao_brlusd(data)
    cotacao(Moedas.config.ativo_brlusd, data)
  end

  def self.busca_e_registra_tudo(data = Date.today)
    Ativo.all.each do |ativo|
      cotacao(ativo, data)
    end
  end


  #
  # Métodos privados
  #


  # @return Cotacao ActiveRecord object
  def self._busca_e_registra_moeda(ativo, data)
    preco = if ativo.id == Moedas.config.ativo_brlusd.id
              BuscaCotacao.brl_usd
            elsif ativo.id == Moedas.config.ativo_usdbrl.id
              BuscaCotacao.usd_brl(data)
            elsif ativo.id == Moedas.config.ativo_btcbrl.id
              BuscaCotacao.btc_brl
            else
              raise StandardError, "Tipo de moeda #{ativo.tipo} ativo ID #{ativo.id} não suportado para busca de cotação"
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
      data_efetiva = Utils.ajusta_data(data_efetiva - 1.day)
      preco = BuscaCotacao.acao(ativo.nome, data_efetiva, bolsa)
      Rails.logger.debug("Tentando nova cotação para #{ativo.nome} na data #{data_efetiva}")
      tentativas -= 1
    end

    # Como podemos ter escolhido uma data diferente da fornecida, ver se já temos o registro
    # dela e "sobreescrever"
    Cotacao.find_by(ativo: ativo, data: data_efetiva).try(:destroy)
    Cotacao.create!(ativo: ativo, data: data_efetiva, valor_unit: preco)
  end

end
