
# Posição de uma Carteira em determinada data.
class Posicao

  attr_reader :carteira, :data, :investidor

  def initialize(carteira, data)
    @carteira = carteira # ActiveRecord Carteira
    @data = data > Date.today ? Date.today : data
    @investidor = carteira.investidor
    @valor_usdbrl = CotacaoService.moedas('USDBRL', data).valor_unit
    @posicao_ativos = [] # lista de PosicaoAtivos
    @referencia = @carteira.referencia
  end

  def ativos
    lista = []
    posicao_ativos.each do |posicao_ativo|
      lista.push posicao_ativo.ativo
    end

    lista
  end

  # Quais ativos eu tenho na carteira até determinada data?
  #
  # @return lista de PosicaoAtivo
  def posicao_ativos
    return @posicao_ativos unless @posicao_ativos.empty?

    resultado = _ativos_quantidade(@carteira, @data)
    resultado.each do |ativo_id, quantidade|
      posicao_ativo = PosicaoAtivo.new(@carteira, ativo_id, @data, quantidade)
      @posicao_ativos.push posicao_ativo
    end

    @posicao_ativos
  end

  def por_corretora
    pc = {}
    posicao_ativos.each do |posicao_ativo|
      corretora_nome = posicao_ativo.corretora.nome
      tipo = posicao_ativo.ativo.tipo
      pc[corretora_nome] = {} unless corretora_nome.in? pc
      pc[corretora_nome][tipo] = [] unless tipo.in? pc[corretora_nome]
      pc[corretora_nome][tipo].push posicao_ativo
    end

    # fazer o sort agora por tamanho de posição. Este é o padrão de display na XP por exemplo
    pc_sorted = pc.clone
    pc.each do |corretora_nome, tipos|
      tipos.each do |tipo, posicao_posicao|
        pc_sorted[corretora_nome][tipo] = posicao_posicao.sort_by { |pa| pa.valor_em_brl }.reverse
      end
    end

    pc_sorted
  end

  def total_ativos_por_corretora
    tc = {}
    posicao_ativos.each do |posicao_ativo|
      moeda = posicao_ativo.ativo.moeda
      corretora = posicao_ativo.corretora
      tc[corretora] = { 'USD' => 0, 'BRL' => 0 } unless corretora.in? tc
      tc[corretora][moeda] += posicao_ativo.valor
    end

    tc
  end

  def porcentagem_por_moeda
    moeda_valores = {}
    moeda_valores['USD'] = 0
    moeda_valores['BRL'] = 0

    # Calcula valores em ativos
    posicao_ativos.each do |posicao_ativo|
      moeda = posicao_ativo.ativo.moeda
      moeda_valores[moeda] += posicao_ativo.valor_em_brl
    end

    # Soma valores em CCs
    moeda_valores['USD'] += ContaCorrente.saldo_cc_usd(@carteira, @data) * @valor_usdbrl
    moeda_valores['BRL'] += ContaCorrente.saldo_cc_brl(@carteira, @data)

    # Calcula porcentagem tudo
    percent_moeda = {}
    moeda_valores.each { |moeda, valor| percent_moeda[moeda] = ((valor / total_geral) * 100).round(2) }

    percent_moeda
  end

  def total_investido(corretora = nil)
    query = @carteira.movimentacoes.where('DATE(data) <= DATE(?)', @data)
    if corretora
      query = query.where(corretora: corretora )
    end
    query.total
  end

  def total_ativos(corretora = nil)
    total_ativos = 0
    posicao_ativos.each do |ap|
      next if corretora && ap.corretora.id != corretora.id

      total_ativos += ap.valor_em_brl
    end

    total_ativos
  end

  def total_fii
    total = 0
    posicao_ativos.each do |ap|
      total += ap.valor_em_brl if ap.ativo.fii?
    end

    total
  end

  def saldo_cc_total(corretora = nil)
    ContaCorrente.saldo_cc_total(@carteira, @data, corretora)
  end

  def total_geral(corretora = nil)
    total_ativos(corretora) + saldo_cc_total(corretora)
  end

  def rentabilidade(corretora = nil)
    (total_geral(corretora) / total_investido(corretora) - 1) * 100
  end

  def rendimento(corretora = nil)
    total_geral(corretora) - total_investido(corretora)
  end

  def porcentagem_ativo(ativo)
    ap = busca_posicao_ativo(ativo)
    ap ? (ap.valor_em_brl / total_geral * 100) : 0
  end

  def corretoras
    corretoras = []
    posicao_ativos.each do |posicao_ativo|
      corretoras.push posicao_ativo.corretora
    end

    corretoras.uniq
  end

  # def total_c_e_v
  #   @carteira.operacoes
  #     .where("operacoes.data::date <= '#{@data}'")
  #     .sum('quantidade * valor_unit * usdbrl')
  # end

  def busca_posicao_ativo(ativo)
    ap_buscado = nil
    @posicao_ativos.each do |ap|
      ap_buscado = ap if ap.ativo == ativo
    end

    ap_buscado
  end

  #
  # Private
  #

  # Retorna os ativos e suas quantidades na carteira
  #
  # @return: lista de tuplas [ativo_id, quantidade]
  def _ativos_quantidade(carteira, data)
    data_str = data.strftime '%F'
    # Para isso somamos a quantidade que temos de cada ativo
    # e o que for diferente de zero significa que temos o ativo na carteira.
    # Quantidade pode ser negativo, por exemplo, operação de short
    sql = <<~SQL
        SELECT ativos.id, ROUND(SUM(quantidade)::numeric, 10)
        FROM ativos
        JOIN operacoes ON operacoes.ativo_id = ativos.id
        WHERE
            operacoes.carteira_id = #{carteira.id} AND
            operacoes.data::date <= '#{data_str}'
        GROUP BY ativos.id, ativos.nome
        HAVING ROUND(SUM(quantidade)::numeric, 10) <> 0
        ORDER BY ativos.nome ASC;
    SQL

    ActiveRecord::Base.connection.execute(sql).values
  end
end