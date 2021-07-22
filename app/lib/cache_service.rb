class CacheService

  # Porque expirar o cache para dado ativo em determinada data já que é algo que não mudaria?
  # R. Se pedirmos um cotacao para um ativo "hoje", vamos receber a cotacao de ontem ou anteontem
  # porque nosso backend só tem dados com mais de 1 dia de atraso.
  # Passados alguns dias, se pedirmos a cotacao para o mesmo ativo na mesma data, iriamos receber
  # a cotacao correta, do dia exato pedido. Nesse sentido, não podemos gravar o cache indefinidamente.
  # A cotacao de "hoje" esta bom para hoje, passado um tempo, queremos a cotacao correta, ou seja
  # da data efetivamente pedida.
  # Não podemos deixar de ter o cache porque em casos do resolve_cotacao cair na 3a tentativa,
  # ou seja, não tem no backend, não queremos que a cada requisição faça-se uma nova busca na API e novamente
  # não encontre. Tente uma vez para "hoje", senão achar, deixa o cache já armezenar o que achou (ultima cotação)
  # para assim as próximas chamadas serem mais rápidas e não dar timeout em produção.
  def self.fetch_cotacao(ativo, data, &block)
    Rails.cache.fetch(_cache_cotacao_str(ativo, data), expires: 12.hours) do
      block.call
    end
  end

  def self.clear_cotacao(ativo, data)
    Rails.cache.clear(_cache_cotacao_str(ativo, data))
  end

  private

  def self._cache_cotacao_str(ativo, data)
    "cotacao_ativo_ID#{ativo.id}_#{data}"
  end

end