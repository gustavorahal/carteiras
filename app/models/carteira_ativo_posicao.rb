class CarteiraAtivoPosicao

  attr_reader :carteira_ativo, :cotacao, :ativo

  def initialize(carteira_ativo_ref, data, quantidade = nil)
    @carteira_ativo = if carteira_ativo_ref.is_a? CarteiraAtivo
                        carteira_ativo_ref
                      else # passei um ID
                        CarteiraAtivo.includes(:corretora, ativo: :cotacoes).find(carteira_ativo_ref)
                      end
    @ativo = @carteira_ativo.ativo
    @data = data
    @data_str = @data.strftime '%F' # apropriado para SQL
    @quantidade = quantidade
    @cotacao = CotacaoService.cotacao(@ativo, @data)
    raise StandardError, "Não foi possível obter cotação de #{@ativo.nome}" unless @cotacao.is_a? Cotacao
  end

  def data_montagem
    Rails.cache.fetch("data_montagem_ca_id-#{@carteira_ativo.id}", expires_in: 5.seconds) do
      @carteira_ativo
        .operacoes
        .where(mon_ou_des: 1)
        .where("operacoes.data::date <= '#{@data_str}'")
        .order(data: :desc)
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
      select sum(#{sum_str})/sum(quantidade) as preco_medio
      from operacoes
      where carteira_ativo_id = #{@carteira_ativo.id} and 
       operacao in (1,4) and 
       data::date >= '#{data_montagem_str}' and
       data::date <= '#{@data_str}'
    SQL

    ActiveRecord::Base.connection.execute(sql).values[0][0]
  end

  def quantidade
    return @quantidade unless @quantidade.nil?

    @carteira_ativo
      .operacoes
      .where("operacoes.data::date <= '#{@data_str}'")
      .sum(:quantidade)
  end

  def valor_investido
    @carteira_ativo
      .operacoes
      .where("operacoes.data::date <= '#{@data_str}'")
      .sum('valor_unit * quantidade')
  end

  def valor_investido_em_brl
    # sendo o ativo em BRL ou USD, a mesma conta se aplica visto que se
    # ativo em BRL o 'usdbrl' terá 1 de valor.
    @carteira_ativo
      .operacoes
      .where("operacoes.data::date <= '#{@data_str}'")
      .sum('valor_unit * quantidade * usdbrl')
  end

  def valor_posicao
    @cotacao.valor_unit * quantidade.to_f
  end

  def valor_posicao_em_brl
    if @ativo.moeda == 'BRL'
      valor_posicao
    elsif @ativo.moeda == 'USD'
      valor_unit_brl * quantidade.to_f
    end
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
