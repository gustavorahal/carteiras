class CarteiraPosicao

  def initialize(carteira, data)
    @carteira = carteira # ActiveRecord Carteira
    @investidor = carteira.investidor
    @data = data
    @valor_usdbrl = CotacaoService.cotacao_usdbrl(data).valor_unit
    @saldo_cc_por_corretora = nil
    @carteira_ativos_posicoes = [] # lista de CarteiraAtivoPosicao
    @valor_por_book = nil
    @porcentagem_por_book = nil
    @total_ativos = nil
  end

  def contem?(nome_ativo)
    @carteira_ativos_posicoes.each { |cap| return true if cap.carteira_ativo.ativo.nome == nome_ativo }
  end

  # Quais ativos eu tenho na carteira até determinada data?
  #
  # @return lista de CarteiraAtivoPosicao
  def carteira_ativos_posicoes
    return @carteira_ativos_posicoes unless @carteira_ativos_posicoes.empty?

    data_str = @data.strftime '%F'
    # Para isso somamos a quantidade que temos de cada ativo
    # e o que for diferente de zero significa que temos o ativo na carteira.
    # Quantidade pode ser negativo, por exemplo, operação de short
    sql = <<~SQL
      SELECT carteira_ativos.id, ROUND(SUM(quantidade)::numeric, 10)
      FROM carteira_ativos
               INNER JOIN
           operacoes ON operacoes.carteira_ativo_id = carteira_ativos.id
               INNER JOIN
           ativos on carteira_ativos.ativo_id = ativos.id
      WHERE carteira_ativos.carteira_id = #{@carteira.id} AND operacoes.data::date <= '#{data_str}'
      GROUP BY carteira_ativos.id, ativos.nome
      HAVING ROUND(SUM(quantidade)::numeric, 10) <> 0
      ORDER BY book, ativos.nome ASC;
    SQL

    resultado = ActiveRecord::Base.connection.execute(sql).values

    resultado.each do |carteira_ativo_id, quantidade|
      cap = CarteiraAtivoPosicao.new(carteira_ativo_id, @data, quantidade)
      @carteira_ativos_posicoes.push cap
    end

    @carteira_ativos_posicoes
  end

  def carteira_ativos
    tmp_list = []
    carteira_ativos_posicoes.each { |cap| tmp_list.push cap.carteira_ativo }
    tmp_list
  end

  def carteira_ativos_posicoes_por_corretora
    pc = {}
    carteira_ativos_posicoes.each do |cap|
      ca = cap.carteira_ativo
      corretora_nome = ca.corretora.nome
      tipo = ca.ativo.tipo
      pc[corretora_nome] = {} unless corretora_nome.in? pc
      pc[corretora_nome][tipo] = [] unless tipo.in? pc[corretora_nome]
      pc[corretora_nome][tipo].push cap
    end

    # fazer o sort agora por tamanho de posição. Este é o padrão de display na XP por exemplo
    pc_sorted = pc.clone
    pc.each do |corretora_nome, tipos|
      tipos.each do |tipo, carteira_ativos_posicoes|
        pc_sorted[corretora_nome][tipo] = carteira_ativos_posicoes.sort_by { |cap| cap.valor_posicao_em_brl }.reverse
      end
    end

    pc_sorted
  end

  def total_ativos_por_corretora
    tc = {}
    carteira_ativos_posicoes.each do |cap|
      moeda = cap.carteira_ativo.ativo.moeda
      ca = cap.carteira_ativo
      tc[ca.corretora] = { moeda => 0 } unless ca.corretora.in? tc
      tc[ca.corretora][moeda] += cap.valor_posicao
    end

    tc
  end

  def porcentagem_por_book
    return @porcentagem_por_book unless @porcentagem_por_book.nil?

    @porcentagem_por_book = {}

    carteira_ativos_posicoes.each do |cap|
      book = cap.carteira_ativo.book
      @porcentagem_por_book[book] = 0 unless book.in? @porcentagem_por_book
      @porcentagem_por_book[book] += (cap.valor_posicao_em_brl / total_geral) * 100
    end

    @porcentagem_por_book
  end

  def valor_por_book
    return @valor_por_book unless @valor_por_book.nil?

    @valor_por_book = {}
    carteira_ativos_posicoes.each do |cap|
      book = cap.carteira_ativo.book
      @valor_por_book[book] = 0 unless book.in? @valor_por_book
      @valor_por_book[book] += cap.valor_posicao_em_brl
    end

    @valor_por_book
  end

  def total_investido
    total_c_e_v + saldo_cc_total
  end

  def total_ativos
    return @total_ativos unless @total_ativos.nil?

    @total_ativos = 0
    carteira_ativos_posicoes.each do |cap|
      @total_ativos += cap.valor_posicao_em_brl
    end

    @total_ativos
  end

  def saldo_cc_total
    ContaCorrente.saldo_cc_total(@carteira.investidor, @data)
  end

  def total_geral
    total_ativos + saldo_cc_total
  end

  def rentabilidade
    (total_geral / total_investido - 1) * 100
  end

  def ultimas_operacoes
    Operacao.operacoes_carteira(@carteira.id).limit(5)
  end

  def porcentagem_carteira_ativo(ca)
    cap = _busca_cap(ca)
    cap ? (cap.valor_posicao_em_brl / total_geral * 100) : 0
  end

  def valor_posicao_carteira_ativo(ca)
    cap = _busca_cap(ca)
    cap ? cap.valor_posicao_em_brl : 0
  end

  def valor_teorico_carteira_ativo(ca)
    return 0 if ca.porcentagem.nil? or ca.porcentagem.zero?
    total_geral * (ca.porcentagem / 100)
  end

  def total_c_e_v
    CarteiraAtivo
      .joins(:operacoes)
      .where(carteira_id: @carteira.id)
      .where("operacoes.data::date <= '#{@data}'")
      .sum('quantidade * valor_unit * usdbrl')
  end


  #
  # Privados
  #

  private

  def _busca_cap(ca)
    cap_buscado = nil
    @carteira_ativos_posicoes.each do |cap|
      cap_buscado = cap if cap.carteira_ativo == ca
    end

    cap_buscado
  end


end