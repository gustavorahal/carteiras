

class AtivoPosicao

  def initialize(carteira_ativo, quantidade, corretora, data_fim, valor_usdbrl)
    @carteira_ativo = carteira_ativo # ActiveRecord CarteiraAtivo
    @quantidade = quantidade
    @corretora = corretora
    @data_fim = data_fim
    @valor_usdbrl = valor_usdbrl
    @preco_atual = nil
    @preco_medio = nil
    @data_montagem = nil
    @cotacao_atual = nil
  end

  def quantidade
    @quantidade
  end

  def corretora
    @corretora
  end

  def book
    @carteira_ativo.book
  end

  def nome_ativo
    @carteira_ativo.ativo.nome_completo
  end

  def tipo_ativo
    @carteira_ativo.ativo.tipo
  end

  def cotacao_atual
    return @cotacao_atual unless @cotacao_atual.nil?

    @cotacao_atual = Cotacao.ultima_cotacao(@carteira_ativo.ativo_id)
  end

  def data_montagem
    return @data_montagem unless @data_montagem.nil?

    @data_montagem = @carteira_ativo.data_montagem
  end

  def valor_posicao
    preco_atual * @quantidade.to_f
  end

  def preco_atual
    return @preco_atual unless @preco_atual.nil?

    @ultima_cotacao = Cotacao.ultima_cotacao(@carteira_ativo.ativo_id)
    if @carteira_ativo.ativo.moeda == 'USD'
      @preco_atual = cotacao_atual.valor_unit * @valor_usdbrl
    else
      @preco_atual = cotacao_atual.valor_unit
    end
    @preco_atual
  end

  def preco_atual_data
    @ultima_cotacao.data
  end

  def preco_medio
    return @preco_medio unless @preco_medio.nil?

    @preco_medio = Operacao.preco_medio(@carteira_ativo.id, @data_montagem, @data_fim)
  end

  def rentabilidade
    ((preco_atual / preco_medio) - 1) * 100
  end

end
