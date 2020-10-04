class CarteiraAtivoPosicao

  attr_reader :carteira_ativo

  def initialize(carteira_ativo_ref, data, quantidade = nil)
    @carteira_ativo = if carteira_ativo_ref.is_a? CarteiraAtivo
                        carteira_ativo_ref
                      else # passei um ID
                        CarteiraAtivo.includes(:corretora, ativo: :cotacoes).find(carteira_ativo_ref)
                      end
    @data = data
    @data_str = @data.strftime '%F' # apropriado para SQL
    @quantidade = quantidade
  end

  def data_montagem
    Rails.cache.fetch("data_montagem_ca_id-#{@carteira_ativo.id}", expires_in: 5.seconds) do
      @carteira_ativo
        .operacoes
        .where(mon_ou_des: 1)
        .where("operacoes.data <= '#{@data_str}'::date")
        .order(data: :desc)
        .limit(1)[0].data
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
  def preco_medio(moeda: 'BRL')
    data_montagem_str = data_montagem.strftime '%F'

    sum_str = if @carteira_ativo.ativo.moeda == 'USD' && moeda == 'BRL'
                'quantidade * valor_unit * usdbrl'
              else # não temos valor de BRL para USD
                'quantidade * valor_unit'
              end

    sql = <<~SQL
      select sum(#{sum_str})/sum(quantidade) as preco_medio
      from operacoes
      where carteira_ativo_id = #{@carteira_ativo.id} and 
       operacao = 1 and 
       data >= '#{data_montagem_str}'::date and
       data <= '#{@data_str}'::date
    SQL

    ActiveRecord::Base.connection.execute(sql).values[0][0]
  end

  def cotacao
    Cotacao.cotacao_ativo(@carteira_ativo.ativo.id, @data)
  end

  def quantidade
    return @quantidade unless @quantidade.nil?

    @carteira_ativo
      .operacoes
      .where("operacoes.data <= '#{@data_str}'::date")
      .sum(:quantidade)
  end

  def valor_investido(moeda: 'BRL')
    if moeda == 'BRL'
      @carteira_ativo
        .operacoes
        .where("operacoes.data <= '#{@data_str}'::date")
        .sum('valor_unit * quantidade * usdbrl')
    else # USD
      # FIXME:
      # não temos a cotacao brlusd armazenada a época para definir qual a cotação usar
      @carteira_ativo
        .operacoes
        .where("operacoes.data <= '#{@data_str}'::date")
        .sum('valor_unit * quantidade')
    end
  end

  def valor_posicao(moeda: 'BRL')
    cotacao ? cotacao.valor_unit_moeda(@data, moeda: moeda) * quantidade.to_f : 0
  end

  def rentabilidade
    cotacao ? ((cotacao.valor_unit_moeda(@data) / preco_medio) - 1) * 100 : 0
  end

end
