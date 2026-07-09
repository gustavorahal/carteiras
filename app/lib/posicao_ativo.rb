class PosicaoAtivo

  attr_reader :cotacao, :ativo

  def initialize(carteira_ref, ativo_ref, data, quantidade = nil)
    @carteira = if carteira_ref.is_a? Carteira
                  carteira_ref
                else # passei um ID
                  Carteira.find(carteira_ref)
                end
    @ativo = if ativo_ref.is_a? Ativo
               ativo_ref
             else # passei um ID
               Ativo.find(ativo_ref)
             end
    @operacoes_ativo = @carteira.operacoes.where(ativo_id: @ativo.id).where('data <= ?', data)
    @data = data
    @quantidade = quantidade
    @cotacao = CotacaoService.cotacao(@ativo, @data)

    raise StandardError, "PosicaoAtivo: Não foi possível obter cotação de #{@ativo.nome}" unless @cotacao.is_a? Cotacao
  end

  def operacoes
    @operacoes_ativo
  end

  def corretora
    # Faz sentido inferir que o ativo esta na corretora em que a ultima operação foi feita
    # O "first" é porque a ordem das operacoes e decrescente
    @operacoes_ativo.first.corretora
  end

  def data_montagem
    @operacoes_ativo.where(mon_ou_des: 1).limit(1)[0].data
  end

  def preco_medio
    sum_str = 'quantidade * valor_unit'
    _preco_medio_sql(sum_str)
  end

  def preco_medio_em_brl
    if @ativo.moeda_negociacao == 'USD'
      sum_str = 'quantidade * valor_unit * usdbrl'
      _preco_medio_sql(sum_str)
    else
      preco_medio
    end
  end

  def quantidade
    return @quantidade unless @quantidade.nil?

    @operacoes_ativo.sum(:quantidade)
  end

  def valor_investido
    # O valor em 31/12/2019 deve ser inserido pelo valor do custo médio das ações multiplicado
    # pela quantidade de ativos nesta mesma data.
    # Fonte: https://blog.clear.com.br/aprenda-como-declarar-acoes-no-imposto-de-renda/
    quantidade * preco_medio
    #@operacoes_ativo.where('DATE(data) >= DATE(?)', data_montagem).sum('valor_unit * quantidade')
  end

  def valor_investido_em_brl
    quantidade * preco_medio_em_brl
  end

  def valor
    @cotacao.valor_unit * quantidade.to_f
  end

  def valor_em_brl
    if @ativo.moeda_negociacao == 'BRL'
      valor
    elsif @ativo.moeda_negociacao == 'USD'
      _valor_unit_brl * quantidade.to_f
    end
  end

  def rentabilidade
    ((@cotacao.valor_unit / preco_medio) - 1) * 100
  end

  def rentabilidade_em_brl
    ((_valor_unit_brl / preco_medio_em_brl) - 1) * 100
  end


  #
  # Private
  #

  def _valor_unit_brl
    @cotacao.valor_unit * CotacaoService.moedas('USDBRL', @data).valor_unit
  end

  # Calcula preço médio de compra
  #
  # Q & A
  # -----
  #
  # 1. Porque pegar apenas operações de compra (ou short)? não teria que incluir pequenas vendas desde a data
  # de montagem?
  #  R. se desejo auferir os ganhos, o fato de ter vendido por 12 quando paguei 10, por exemplo,
  #  não deveria aumentar o preço médio para 11. O preço médio de compra continuaria 10 enquanto
  #  referência para ganhos ou perdas de vendas futuras.
  def _preco_medio_sql(sum_str)
    operacoes = @operacoes_ativo
                .where(operacao: %i[C S])
                .where(data: data_montagem..@data)

    operacoes.sum(Arel.sql(sum_str)) / operacoes.sum(:quantidade)
  end

end
