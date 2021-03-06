
# Posição da Carteira em determinada data. Quais ativos e qual a posicao deles
class CarteiraAtivos

  attr_reader :carteira

  def initialize(carteira, data)
    @carteira = carteira # ActiveRecord Carteira
    @investidor = carteira.investidor
    @data = data
    @valor_usdbrl = CotacaoService.cotacao_usdbrl(data).valor_unit
    @saldo_cc_por_corretora = nil
    @saldo_cc_total = nil
    @ativos_posicao = [] # lista de CarteiraAtivoPosicao
    @total_ativos = nil
    @referencia = @carteira.referencia
  end

  def ativos
    lista = []
    ativos_posicao.each do |ativo_posicao|
      lista.push ativo_posicao.ativo
    end

    lista
  end

  # Quais ativos eu tenho na carteira até determinada data?
  #
  # @return lista de AtivoPosicao
  def ativos_posicao
    return @ativos_posicao unless @ativos_posicao.empty?

    data_str = @data.strftime '%F'
    # Para isso somamos a quantidade que temos de cada ativo
    # e o que for diferente de zero significa que temos o ativo na carteira.
    # Quantidade pode ser negativo, por exemplo, operação de short
    sql = <<~SQL
      SELECT ativos.id, ROUND(SUM(quantidade)::numeric, 10)
      FROM ativos
      JOIN operacoes ON operacoes.ativo_id = ativos.id
      WHERE
          operacoes.carteira_id = #{@carteira.id} AND
          operacoes.data::date <= '#{data_str}'
      GROUP BY ativos.id, ativos.nome
      HAVING ROUND(SUM(quantidade)::numeric, 10) <> 0
      ORDER BY ativos.nome ASC;
    SQL

    resultado = ActiveRecord::Base.connection.execute(sql).values

    resultado.each do |ativo_id, quantidade|
      cap = AtivoPosicao.new(@carteira, ativo_id, @data, quantidade)
      @ativos_posicao.push cap
    end

    @ativos_posicao
  end

  def ativos_posicao_por_corretora
    pc = {}
    ativos_posicao.each do |cap|
      corretora_nome = cap.corretora.nome
      tipo = cap.ativo.tipo
      pc[corretora_nome] = {} unless corretora_nome.in? pc
      pc[corretora_nome][tipo] = [] unless tipo.in? pc[corretora_nome]
      pc[corretora_nome][tipo].push cap
    end

    # fazer o sort agora por tamanho de posição. Este é o padrão de display na XP por exemplo
    pc_sorted = pc.clone
    pc.each do |corretora_nome, tipos|
      tipos.each do |tipo, carteira_ativos_posicao|
        pc_sorted[corretora_nome][tipo] = carteira_ativos_posicao.sort_by { |cap| cap.valor_em_brl }.reverse
      end
    end

    pc_sorted
  end

  def total_ativos_por_corretora
    tc = {}
    ativos_posicao.each do |ativo_posicao|
      moeda = ativo_posicao.ativo.moeda
      corretora = ativo_posicao.corretora
      tc[corretora] = { 'USD' => 0, 'BRL' => 0 } unless corretora.in? tc
      tc[corretora][moeda] += ativo_posicao.valor
    end

    tc
  end

  def porcentagem_por_moeda
    # Calcula valores em ativos
    moeda_valores = {}
    ativos_posicao.each do |ativo_posicao|
      moeda = ativo_posicao.ativo.moeda
      moeda_valores[moeda] = 0 unless moeda.in? moeda_valores.keys
      moeda_valores[moeda] += ativo_posicao.valor_em_brl
    end

    # Soma valores em CCs
    moeda_valores['USD'] += ContaCorrente.saldo_cc_usd(@carteira.investidor, @data) * @valor_usdbrl
    moeda_valores['BRL'] += ContaCorrente.saldo_cc_brl(@carteira.investidor, @data)

    # Calcula porcentagem tudo
    percent_moeda = {}
    moeda_valores.each { |moeda, valor| percent_moeda[moeda] = ((valor / total_geral) * 100).round(2) }

    percent_moeda
  end

  def total_investido
    total_c_e_v + saldo_cc_total
  end

  def total_ativos
    return @total_ativos unless @total_ativos.nil?

    @total_ativos = 0
    ativos_posicao.each do |cap|
      @total_ativos += cap.valor_em_brl
    end

    @total_ativos
  end

  def saldo_cc_total
    return @saldo_cc_total unless @saldo_cc_total.nil?

    @saldo_cc_total = ContaCorrente.saldo_cc_total(@carteira.investidor, @data)
  end

  def total_geral
    total_ativos + saldo_cc_total
  end

  def rentabilidade
    (total_geral / total_investido - 1) * 100
  end

  def porcentagem_ativo(ativo)
    ap = busca_ativo_posicao(ativo)
    ap ? (ap.valor_em_brl / total_geral * 100) : 0
  end

  def total_c_e_v
    @carteira.operacoes
      .where("operacoes.data::date <= '#{@data}'")
      .sum('quantidade * valor_unit * usdbrl')
  end

  def busca_ativo_posicao(ativo)
    ap_buscado = nil
    @ativos_posicao.each do |ap|
      ap_buscado = ap if ap.ativo == ativo
    end

    ap_buscado
  end

end