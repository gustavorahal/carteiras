class CotacaoService

  # param @ativo: ActiceRecord Ativo
  # param @data: irá tentar buscar cotacao para data dada. Se não for possivel, retornar
  #              ultimo dia antes da data com uma cotacao disponivel
  def self.cotacao(ativo, data)
    Rails.cache.fetch("cotacao_ativo_#{ativo.id}_#{data}", expires_in: 20.seconds) do
      data_cotacao = Utils.ajusta_data(data, ativo)
      Rails.logger.info "CotacaoService.cotacao: Cotação ativo #{ativo.nome}: Data ajustada de #{data} para #{data_cotacao}" if data_cotacao != data

      cotacao = Cotacao.where(ativo: ativo, data: data_cotacao).order(data: :desc).first
      if cotacao
        Rails.logger.info "CotacaoService.cotacao: Cotação para #{ativo.nome} em #{data_cotacao} disponível no BD"
      else
        Rails.logger.info "CotacaoService.cotacao: Buscando cotação para #{ativo.nome} na data #{data_cotacao}"
        case ativo.tipo
        when 'acao', 'fii', 'etf'
          cotacao = _busca_e_registra_acao(ativo, data_cotacao)
        when 'moeda'
          cotacao = _busca_e_registra_moeda(ativo, data_cotacao)
        when 'criptomoeda'
          cotacao = _busca_e_registra_moeda(ativo, data_cotacao)
        when 'tesouro'
          cotacao = _busca_e_registra_tesouro(ativo, data_cotacao)
        when 'fundo'
          cotacao = _busca_e_registra_fundo(ativo, data_cotacao)
        when 'cra', 'debenture'
          # como não temos um jeito automatizado de buscar cra ou debenture
          # retornar ultima cotação
          cotacao = Cotacao.where(ativo: ativo).order(data: :desc).first
        else
          raise StandardError, 'Tipo de ativo não suportado para busca de cotação'
        end
      end

      cotacao
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


  #
  # Pela maneira que nossa Backend funciona, esta função faz algo
  # atipico. Aproveitando que a busca é custosa (download de arquivo de 30MB+)
  # e retorna informações de todos os fundos, vamos aproveitar e atualizar
  # informações de todos os fundos mas retornar só o que foi pedido
  def self._busca_e_registra_fundo(ativo, data)
    cnpjs = Ativo.where(tipo: 'fundo').pluck(:cnpj)
    dados = BuscaFundos.cotas(cnpjs, data.year, data.month)
    dados.each do |cnpj, vl_cotas|
      vl_cotas.each do |vl_cota|
        ativo = Ativo.find_by(cnpj: cnpj)
        data = vl_cota[0].to_date
        unless Cotacao.find_by(ativo: ativo, data: data)
          Cotacao.create!(ativo: ativo, data: data, valor_unit: vl_cota[1])
        end
      end
    end

    Cotacao.find_by(ativo: ativo, data: data)
  end

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
        Rails.logger.info("Desistindo de tentar, pegando última cotacao para #{ativo.nome}")
        return Cotacao.where(ativo_id: ativo.id).last
      end
      data_efetiva = Utils.ajusta_data(data_efetiva - 1.day, ativo)
      preco = BuscaCotacao.acao(ativo.nome, data_efetiva, bolsa)
      Rails.logger.info("Tentando nova cotação para #{ativo.nome} na data #{data_efetiva}")
      tentativas -= 1
    end

    # Como podemos ter escolhido uma data diferente da fornecida, ver se já temos o registro
    # dela e "sobreescrever"
    Cotacao.find_by(ativo: ativo, data: data_efetiva).try(:destroy)
    Cotacao.create!(ativo: ativo, data: data_efetiva, valor_unit: preco)
  end

end
