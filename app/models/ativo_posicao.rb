class AtivoPosicao

  attr_reader :cotacao, :ativo, :corretora

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
    @operacoes_ativo = @carteira.operacoes.where(ativo_id: @ativo.id).where('DATE(data) <= DATE(?)', data)
    # Faz sentido inferir que o ativo esta na corretora em que a ultima operação foi feita
    # O "first" é porque a ordem das operacoes e decrescente
    @corretora = @operacoes_ativo.first.corretora
    @data = data
    @data_str = @data.strftime '%F' # apropriado para SQL
    @quantidade = quantidade
    @cotacao = CotacaoService.cotacao(@ativo, @data)

    raise StandardError, "Não foi possível obter cotação de #{@ativo.nome}" unless @cotacao.is_a? Cotacao
  end

  def operacoes
    @operacoes_ativo
  end

  def data_montagem
    Rails.cache.fetch("data_montagem_carteira_id-#{@carteira.id}_ativo_id-#{@ativo.id}", expires_in: 5.seconds) do
      @operacoes_ativo
        .where(mon_ou_des: 1)
        .limit(1)[0].data
    end
  end

  def preco_medio
    sum_str = 'quantidade * valor_unit'
    _preco_medio_sql(sum_str)
  end

  def preco_medio_em_brl
    if @ativo.moeda == 'USD'
      sum_str = 'quantidade * valor_unit * usdbrl'
      _preco_medio_sql(sum_str)
    else
      preco_medio
    end
  end

  # Calcula preço médio de compra
  #
  # Q & A
  # -----
  #
  # 1. Porque pegar apenas operações de compra? não teria que incluir pequenas vendas desde a data
  # de montagem?
  #  R. se desejo auferir os ganhos, o fato de ter vendido por 12 quando paguei 10, por exemplo,
  #  não deveria aumentar o preço médio para 11. O preço médio de compra continuaria 10 enquanto
  #  referência para ganhos ou perdas de vendas futuras.
  def _preco_medio_sql(sum_str)
    data_montagem_str = data_montagem.strftime '%F'
    sql = <<~SQL
      SELECT sum(#{sum_str})/sum(quantidade) AS preco_medio
      FROM operacoes
      WHERE 
       carteira_id = #{@carteira.id} AND 
       ativo_id = #{@ativo.id} AND  
       operacao IN (1,4) AND 
       data::date >= '#{data_montagem_str}' AND
       data::date <= '#{@data_str}'
    SQL

    ActiveRecord::Base.connection.execute(sql).values[0][0]
  end

  def quantidade
    return @quantidade unless @quantidade.nil?

    @operacoes_ativo
      .sum(:quantidade)
  end

  def valor_investido
    @operacoes_ativo.where('DATE(data) >= DATE(?)', data_montagem).sum('valor_unit * quantidade')
  end

  def valor_investido_em_brl
    # sendo o ativo em BRL ou USD, a mesma conta se aplica visto que se
    # ativo em BRL o 'usdbrl' terá 1 de valor.
    @operacoes_ativo.where('DATE(data) >= DATE(?)', data_montagem).sum('valor_unit * quantidade * usdbrl')
  end

  def valor
    @cotacao.valor_unit * quantidade.to_f
  end

  def valor_em_brl
    if @ativo.moeda == 'BRL'
      valor
    elsif @ativo.moeda == 'USD'
      valor_unit_brl * quantidade.to_f
    end
  end

  def valor_montagem
    quantidade * preco_medio
  end

  def rentabilidade
    ((@cotacao.valor_unit / preco_medio) - 1) * 100
  end

  def rentabilidade_em_brl
    ((valor_unit_brl / preco_medio_em_brl) - 1) * 100
  end

  def valor_unit_brl
    @cotacao.valor_unit * CotacaoService.cotacao_usdbrl(@data).valor_unit
  end


end
