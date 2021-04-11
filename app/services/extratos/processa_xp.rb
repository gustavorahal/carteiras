class ProcessaXp < ProcessaBase

  def self.dividendo(texto)
    # Exemplo: DIVIDENDOS DE CLIENTES VIVT4 S/ 300
    regex_dividendo = %r{DIVIDENDOS DE CLIENTES (\w+) S/ ([0-9.]+)$}
    _processa_common(texto, regex_dividendo)
  end

  def self.jcp(texto)
    # Exemplos:
    # JUROS S/ CAPITAL DE CLIENTES RADL3 S/ 100
    # JUROS S/ CAPITAL DE CLIENTES PETR4 S/ 1.400
    regex_jcp = %r{JUROS S/ CAPITAL DE CLIENTES (\w+) S/ ([0-9.]+)$}
    _processa_common(texto, regex_jcp)
  end

  def self.rendimento(texto)
    # Exemplo: RENDIMENTOS DE CLIENTES XPML11 S/ 170
    regex_rendimento = %r{RENDIMENTOS DE CLIENTES (\w+) S/ ([0-9.]+)$}
    _processa_common(texto, regex_rendimento)
  end

  def self.resgate?(texto)
    # Exemplo: TED BCO 1 AGE 4858 CTA 503770 - RETIRADA EM C/C
    regex_resgate = %r{TED BCO .+ RETIRADA EM C/C}
    match = regex_resgate.match(texto)
    match ? true : false
  end

  def self.aporte?(texto)
    # Exemplos:
    # TED - RECEBIMENTO DE TED - SPB
    # RECEBIMENTO DE TED - SPB
    # TED BCO 001 AGE 4858 CTA 503770 - RECEBIMENTO DE TED - SPB
    regex_aporte = %r{RECEBIMENTO DE TED}
    match = regex_aporte.match(texto)
    match ? true : false
  end


  #
  # Private
  #

  def self._processa_common(texto, regex)
    match = regex.match(texto)
    return nil unless match

    nome_ativo = match[1]
    quantidade = match[2].gsub('.', '') # números podem aparecer no formato "1.400" (para 1400)
    [nome_ativo, quantidade]
  end

end