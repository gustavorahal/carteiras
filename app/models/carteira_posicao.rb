class CarteiraPosicao

  def initialize(carteira, data_fim)
    @carteira = carteira # ActiveRecord Carteira
    @data_fim = data_fim
    @valor_usdbrl = Cotacao.cotacao_usdbrl.valor_unit
    @total_c_e_v = nil
    @total_geral = nil
    @total_ativos = nil
    @ativos_posicoes = nil
    @saldo_cc_por_corretora = nil
  end

  # Quais ativos eu tenho na carteira até determinada data?
  def ativos_posicoes
    return @ativos_posicoes unless @ativos_posicoes.nil?

    data_fim_str = @data_fim.strftime '%F'
    # Para isso somamos a quantidade que temos de cada ativo
    # e o que for diferente de zero significa que temos o ativo na carteira.
    # Quantidade pode ser negativo. Exemplo: operação de short
    sql = <<~SQL
      SELECT carteira_ativos.id, ROUND(SUM(quantidade)::numeric, 10), operacoes.corretora
      FROM carteira_ativos
               INNER JOIN
           operacoes ON operacoes.carteira_ativo_id = carteira_ativos.id
      WHERE carteira_ativos.carteira_id = #{@carteira.id} AND operacoes.data <= '#{data_fim_str}'
      GROUP BY carteira_ativos.id, operacoes.corretora
      HAVING ROUND(SUM(quantidade)::numeric, 10) <> 0
      ORDER BY book ASC;
    SQL

    resultado = ActiveRecord::Base.connection.execute(sql).values

    @ativos_posicoes = []

    resultado.each do |carteira_ativo_id, quantidade, corretora|
      ap = AtivoPosicao.new(CarteiraAtivo.includes(:ativo).find(carteira_ativo_id),
                                       quantidade, corretora, @data_fim)
      @ativos_posicoes.push ap
    end

    @ativos_posicoes
  end

  def ativos_posicoes_por_corretora
    pc = {}
    ativos_posicoes.each do |ativo_posicao|
      corretora = ativo_posicao.corretora
      pc[corretora] = [] unless corretora.in? pc
      pc[corretora].push ativo_posicao
    end

    pc
  end

  def total_c_e_v
    return @total_c_e_v unless @total_c_e_v.nil?

    @total_c_e_v = CarteiraAtivo
                       .joins(:operacoes)
                       .where(carteira_id: @carteira.id)
                       .sum('quantidade * valor_unit * usdbrl')
  end

  def total_ativos
    return @total_ativos unless @total_ativos.nil?

    @total_ativos = 0
    ativos_posicoes.each do |ativo_posicao|
      @total_ativos += ativo_posicao.valor_posicao
    end

    @total_ativos
  end

  def total_geral
    total_ativos + saldo_cc_total
  end

  def corretoras
    crrtrs = {}
    ativos_posicoes.each do |ativo_posicao|
      crrtrs[ativo_posicao.corretora] = true
    end

    crrtrs.keys
  end

  def saldo_cc_por_corretora
    return @saldo_cc_por_corretora unless @saldo_cc_por_corretora.nil?

    @saldo_cc_por_corretora = {}
    corretoras.each do |corretora|
      @saldo_cc_por_corretora[corretora] = {} unless corretora.in? @saldo_cc_por_corretora
      %w[BRL USD].each do |moeda|
        @saldo_cc_por_corretora[corretora][moeda] = Extrato
                                     .where(investidor_id: @carteira.investidor.id,
                                     moeda: moeda, corretora: corretora)
                                     .sum(:valor).round(2)
      end
    end

    @saldo_cc_por_corretora
  end

  def saldo_cc_total
    total = 0
    saldo_cc_por_corretora.each do |corretora, moedas_saldo|
      moedas_saldo.each do |moeda, saldo|
        if moeda == 'USD'
          total += (saldo * @valor_usdbrl)
        else
          total += saldo
        end
      end
    end

    total
  end

  def porcentagem_por_book
    pb = {}
    ativos_posicoes.each do |ativo_posicao|
      book = ativo_posicao.book
      pb[book] = 0 unless book.in? pb
      pb[book] += (ativo_posicao.valor_posicao / total_geral) * 100
    end

    pb
  end

  def total_investido
    total_c_e_v + saldo_cc_total
  end

  def rentabilidade
    (total_geral / total_investido - 1) * 100
  end

  def ultimas_operacoes
    Operacao.operacoes_carteira(@carteira.id).limit(5)
  end

end