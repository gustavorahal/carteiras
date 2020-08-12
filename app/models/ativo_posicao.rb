

class AtivoPosicao

  attr_reader :quantidade, :carteira_ativo

  def initialize(carteira_ativo, quantidade, data_fim)
    @carteira_ativo = carteira_ativo # ActiveRecord CarteiraAtivo
    @quantidade = quantidade
    @data_fim = data_fim
    @preco_atual = nil
    @preco_medio = nil
    @data_montagem = nil
    @cotacao_atual = nil
  end

  def book
    @carteira_ativo.book
  end

  def nome_amigavel
    @carteira_ativo.ativo.nome_amigavel
  end

  def nome
    @carteira_ativo.ativo.nome
  end

  def tipo_ativo
    @carteira_ativo.ativo.tipo
  end

  def ultima_cotacao
    return @cotacao_atual unless @cotacao_atual.nil?

    @cotacao_atual = @carteira_ativo.ultima_cotacao
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
      @preco_atual = ultima_cotacao.valor_unit * Cotacao.cotacao_usdbrl.valor_unit
    else
      @preco_atual = ultima_cotacao.valor_unit
    end
    @preco_atual
  end

  def preco_atual_data
    @ultima_cotacao.data
  end

  def preco_medio
    return @preco_medio unless @preco_medio.nil?

    @preco_medio = @carteira_ativo.preco_medio(@data_fim)
  end

  def rentabilidade
    ((preco_atual / preco_medio) - 1) * 100
  end

end
