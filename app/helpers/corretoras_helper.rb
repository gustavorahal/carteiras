module CorretorasHelper

  def oper_corretora_url(corretora, ativo, operacao)
    url = nil

    begin
      url = send("#{corretora.nome.downcase}_url", ativo, operacao)
    rescue NoMethodError
      Rails.logger.debug("Url de btn operacao para corretora #{corretora.nome} não definido")
    end

    url
  end

  # Exemplos
  # https://nova.vitreo.com.br/painel/investir/renda-variavel/boleta/ITSA4/Comprar
  # https://nova.vitreo.com.br/painel/investir/renda-variavel/boleta/ITSA4/Vender
  def vitreo_url(ativo, operacao)
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