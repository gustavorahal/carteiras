class CotacaoService



  # param @ativo ActiceRecord Ativo
  def self.cotacao(ativo, data)
    Rails.cache.fetch("cotacao_ativo_#{ativo.id}", expires_in: 3.seconds) do
      cotacao = Cotacao.where(ativo_id: ativo.id, data: data).first
      return cotacao if cotacao

      Rails.logger.debug "Buscando cotação para #{ativo.nome}"
      begin
        case ativo.tipo
        when 'acao', 'fii'
          return _busca_e_registra_acao(ativo, data)
        when 'moeda'
          return _busca_e_registra_moeda(ativo, data)
        when 'criptomoeda'
          return _busca_e_registra_moeda(ativo, data)
        when 'tesouro'
          return _busca_e_registra_tesouro(ativo)
        when 'fundo'
          # como não temos um jeito automatizado de buscar fundos
          # retornar ultima cotação
          return Cotacao.where(ativo_id: ativo.id).order(data: :desc).first
        else
          puts "invalido"
        end
      rescue => e
        Rails.logger.error e.message
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

    Cotacao.create!(ativo_id: ativo.id, valor_unit: preco, data: Date.today)
  end

  # @return Cotacao ActiveRecord object
  def self._busca_e_registra_tesouro(ativo)
    data, preco = BuscaCotacao.tesouro ativo.nome
    # Para a aplicação, a cotação que importa é a ultima cotacao conhecida
    # se no sábado a cotacao seria a da sexta, para efeitos práticos,
    # a cotacao pode ser copiada para sábado. Assim, sempre considera a data
    # de hoje mesmo que venha uma data de 1 ou 2 dias atrás
    Cotacao.create!(ativo_id: ativo.id, valor_unit: preco, data: Date.today)
  end

  # @return Cotacao ActiveRecord object
  def self._busca_e_registra_acao(ativo, data)
    ativo_str = ativo.nome
    ativo_str += '.SA' if ativo.moeda == 'BRL'

    preco = BuscaCotacao.acao(ativo_str, data).to_f
    Cotacao.create!(ativo_id: ativo.id, valor_unit: preco, data: Date.today)
  end

end
