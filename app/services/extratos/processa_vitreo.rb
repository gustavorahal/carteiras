class ProcessaVitreo < ProcessaBase

  def self.dividendo(texto)
    # Exemplo:
    # Dividendos 100 VALE3
    # Dividendos 100           VALE3
    regex_dividendo = %r{Dividendos ([0-9.]+) \s+ (\w+)}
    _processa_common(texto, regex_dividendo)
  end

  def self.jcp(texto)
    # Exemplos:
    # Juros s/capital 100 VALE3
    # Juros s/capital 100       VALE3
    regex_jcp = %r{Juros s/capital ([0-9.]+) \s+ (\w+)}
    _processa_common(texto, regex_jcp)
  end

  def self.rendimento(texto)
    # Exemplo: Pagamento de Rendimentos RBRF11
    regex_rendimento = %r{Pagamento de Rendimentos (\w+)}
    match = regex_rendimento.match(texto)
    return nil unless match

    [match[1], 0] # nome do ativo
  end

  def self.resgate?(texto)
    # Exemplos:
    # TED BCO 341 AGE 8294 CTA 04463 4 - RETIRADA EM C/C
    regex_aporte = %r{TED BCO .* RETIRADA EM C/C}
    match = regex_aporte.match(texto)
    match ? true : false
  end

  def self.aporte?(texto)
    # Exemplos:
    # TED BCO 033 AGE 4292 CTA 1082370 2 - CREDITO EM C/C
    regex_aporte = %r{TED BCO .* CREDITO EM C/C}
    match = regex_aporte.match(texto)
    match ? true : false
  end

  #
  # Private
  #

  def self._processa_common(texto, regex)
    match = regex.match(texto)
    return nil unless match

    quantidade = match[1].gsub('.', '') # números podem aparecer no formato "1.400" (para 1400)
    nome_ativo = match[2]
    [nome_ativo, quantidade]
  end

end