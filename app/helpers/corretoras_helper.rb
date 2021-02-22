module CorretorasHelper

  def oper_corretora_url(corretora, ativo, operacao)
    url = nil

    begin
      url = send("#{corretora.nome.downcase}_url", ativo, operacao)
    rescue NoMethodError
      Rails.logger.debug("Url de btn operacao para corretora #{corretora.nome} não definido")
      return nil
    end

    url
  end

  # Exemplos
  # https://nova.vitreo.com.br/painel/investir/renda-variavel/boleta/ITSA4/Comprar
  # https://nova.vitreo.com.br/painel/investir/renda-variavel/boleta/ITSA4/Vender
  def vitreo_url(ativo, operacao)
    if ativo.na_bolsa?
      vitreo_url_acao(ativo, operacao)
    elsif ativo.tipo == 'tesouro'
      vitreo_url_tesouro(ativo, operacao)
    else
      nil
    end
  end

  def vitreo_url_tesouro(ativo, operacao)
    titulos = { 'Tesouro Selic 2027' => 'lft-20270301',
                'Tesouro Selic 2025' => 'abc' }
    titulo = titulos[ativo.nome]
    return nil if titulo.nil?

    oper_str = operacao == 'C' ? 'investir' : 'resgatar'

    "https://nova.vitreo.com.br/painel/investir/tesouro-direto/detalhe/#{titulo}/#{oper_str}"
  end

  def vitreo_url_acao(ativo, operacao)
    url = "https://nova.vitreo.com.br/painel/investir/renda-variavel/boleta/#{ativo.nome}"
    url += '/Vender' if operacao == 'V'
    url += '/Comprar' if operacao == 'C'

    url
  end

  # Exemplos
  # https://pit.avenue.us/operations/instruments/AAPL/0
  def avenue_url(ativo, operacao)
    "https://pit.avenue.us/operations/instruments/#{ativo.nome}/0"
  end


end