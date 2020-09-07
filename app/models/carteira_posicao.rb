class CarteiraPosicao

  def initialize(carteira, data_fim)
    @carteira = carteira # ActiveRecord Carteira
    @investidor = carteira.investidor
    @data_fim = data_fim
    @valor_usdbrl = Cotacao.cotacao_usdbrl.valor_unit
    @saldo_cc_por_corretora = nil
    @carteira_ativos = [] # lista de ActiveRecord CarteiraAtivo
    @valor_por_book = nil
    @porcentagem_por_book = nil
    @total_ativos = nil
  end

  def contem?(nome_ativo)
    @carteira_ativos.each { |ca| return true if ca.ativo.nome == nome_ativo }
  end

  # Quais ativos eu tenho na carteira até determinada data?
  #
  # @return lista de ActiveRecord CarteiraAtivo
  def carteira_ativos
    return @carteira_ativos unless @carteira_ativos.empty?

    data_fim_str = @data_fim.strftime '%F'
    # Para isso somamos a quantidade que temos de cada ativo
    # e o que for diferente de zero significa que temos o ativo na carteira.
    # Quantidade pode ser negativo. Exemplo: operação de short
    sql = <<~SQL
      SELECT carteira_ativos.id, ROUND(SUM(quantidade)::numeric, 10)
      FROM carteira_ativos
               INNER JOIN
           operacoes ON operacoes.carteira_ativo_id = carteira_ativos.id
               INNER JOIN
           ativos on carteira_ativos.ativo_id = ativos.id
      WHERE carteira_ativos.carteira_id = #{@carteira.id} AND operacoes.data <= '#{data_fim_str}'
      GROUP BY carteira_ativos.id, ativos.nome
      HAVING ROUND(SUM(quantidade)::numeric, 10) <> 0
      ORDER BY book, ativos.nome ASC;
    SQL

    resultado = ActiveRecord::Base.connection.execute(sql).values

    resultado.each do |carteira_ativo_id, quantidade|
      ca = CarteiraAtivo.includes(:corretora, ativo: :cotacoes).find(carteira_ativo_id)
      # FIXME: testar se rola fazer varias chamadas para quantidade
      # #ca.set_quantidade quantidade
      @carteira_ativos.push ca
    end

    @carteira_ativos
  end

  # FIXME usar activerecord query group by depois e desativar isso
  def carteira_ativos_por_corretora
    pc = {}
    carteira_ativos.each do |ca|
      corretora_nome = ca.corretora.nome
      pc[corretora_nome] = [] unless corretora_nome.in? pc
      pc[corretora_nome].push ca
    end

    pc
  end

  def total_ativos
    return @total_ativos unless @total_ativos.nil?

    @total_ativos = 0
    carteira_ativos.each do |ca|
      @total_ativos += ca.valor_posicao
    end

    @total_ativos
  end

  def total_geral
    total_ativos + saldo_cc_total
  end

  def saldo_cc_total
    Rails.cache.fetch("saldo_cc_total_#{@investidor.id}", expires_in: 5.seconds) do
      total_brl = Extrato.joins(:conta_corrente).where('conta_correntes.investidor_id': @carteira.investidor.id,
                                                       'conta_correntes.moeda': 'BRL').sum(:valor)
      total_usd = Extrato.joins(:conta_corrente).where('conta_correntes.investidor_id': @carteira.investidor.id,
                                                       'conta_correntes.moeda': 'USD').sum(:valor)
      total_usdbrl = total_usd * @valor_usdbrl

      total_brl + total_usdbrl
    end
  end

  def porcentagem_por_book
    return @porcentagem_por_book unless @porcentagem_por_book.nil?

    @porcentagem_por_book = {}

    carteira_ativos.each do |ca|
      book = ca.book
      @porcentagem_por_book[book] = 0 unless book.in? @porcentagem_por_book
      @porcentagem_por_book[book] += (ca.valor_posicao / total_geral) * 100
    end

    @porcentagem_por_book
  end

  def valor_por_book
    return @valor_por_book unless @valor_por_book.nil?

    @valor_por_book = {}
    carteira_ativos.each do |ca|
      book = ca.book
      @valor_por_book[book] = 0 unless book.in? @valor_por_book
      @valor_por_book[book] += ca.valor_posicao
    end

    @valor_por_book
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

  def porcentagem_carteira_ativo(ca)
    ca.valor_posicao / total_geral * 100
  end

  def valor_teorico_carteira_ativo(ca)
    total_geral * (ca.porcentagem / 100)
  end

  def total_c_e_v
    CarteiraAtivo
               .joins(:operacoes)
               .where(carteira_id: @carteira.id)
               .sum('quantidade * valor_unit * usdbrl')
  end

end