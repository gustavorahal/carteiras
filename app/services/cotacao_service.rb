class CotacaoService


  def self.busca_e_registra_tudo(data = Date.today)
    Ativo.all.each do |ativo|
      cotacao(ativo, data)
    end
  end

  # param @ativo ActiceRecord Ativo
  def self.cotacao(ativo, data)
    cotacao = Cotacao.where(ativo_id: ativo.id, data: data).first
    return cotacao if cotacao

    Rails.logger.debug "Buscando cotação para #{ativo.nome}"
    begin
      case ativo.tipo
      when 'acao', 'fii'
        return _busca_e_registra_acao(ativo, data)
      when 'moeda'
        return _busca_e_registra_moeda(ativo, data)
      when 'tesouro'
        return _busca_e_registra_tesouro(ativo)
      else
        puts "invalido"
      end
    rescue => e
      Rails.logger.error e.message
    end

  end

  #
  # Métodos privados
  #

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

    Cotacao.create!(ativo_id: ativo.id, valor_unit: preco, data: DateTime.now)
  end

  def self._busca_e_registra_tesouro(ativo)
    data, preco = BuscaCotacao.tesouro ativo.nome
    Cotacao.create!(ativo_id: ativo.id, valor_unit: preco, data: data)
  end

  def self._busca_e_registra_acao(ativo, data)
    ativo_str = ativo.nome
    if ativo.moeda == 'BRL'
      ativo_str = ativo_str + '.SA'
    end

    preco = BuscaCotacao.acao(ativo_str, data).to_f
    Cotacao.create!(ativo_id: ativo.id, valor_unit: preco, data: DateTime.now)
  end

end
