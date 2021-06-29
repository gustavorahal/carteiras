
class Rentabilidade

  def initialize(carteira, data_desde, intervalo = 'M')
    raise StandardError unless intervalo.in? %w[D M Y]

    @carteira = carteira
    @posicoes = _posicoes(data_desde, intervalo)
  end

  # @return [Hash]: Hash de dados sobre rentabilidade mes a mes
  # { '2021-05-11': { 'XP': { :movimentacoes => 123.45, ..} } }
  def mes_a_mes_corretoras
    dados = {}
    @posicoes.each do |posicao|
      dados[posicao.data] = {}
      corretoras.each do |corretora|
        dados[posicao.data][corretora.nome] = _dados_posicao(posicao, corretora)
      end
    end

    dados
  end

  def mes_a_mes_global
    dados = {}
    @posicoes.each do |posicao|
      dados[posicao.data] = _dados_posicao(posicao)
    end

    dados
  end

  def corretoras
    corretoras_tmp = []
    @posicoes.each { |posicao| corretoras_tmp += posicao.corretoras}
    corretoras_tmp.uniq
  end


  #
  # Private
  #

  def _dados_posicao(posicao, corretora = nil)
    dados_posicao = {}
    dados_posicao[:movimentacoes] = _movimentacoes_mes(posicao, corretora)
    dados_posicao[:rentabilidade] = _rentabilidade(posicao, corretora)
    dados_posicao[:rendimento] = _rendimento(posicao, corretora)
    dados_posicao[:total] = posicao.total_geral(corretora)

    dados_posicao
  end

  def _movimentacoes_mes(posicao, corretora)
    beginning_of_month = posicao.data.beginning_of_month
    end_of_month = posicao.data.end_of_month
    query = posicao.carteira.movimentacoes
                   .where("data >= '#{beginning_of_month}'")
                   .where("data <= '#{end_of_month}'")
    if corretora
      query = query.where(corretora: corretora)
    end

    query.sum(:valor)
  end

  def _rentabilidade(posicao, corretora)
    (posicao.total_geral(corretora) / _base_comparacao(posicao, corretora) - 1) * 100
  end

  def _rendimento(posicao, corretora)
    posicao.total_geral(corretora) - _base_comparacao(posicao, corretora)
  end

  def _base_comparacao(posicao, corretora)
    posicao_index = @posicoes.index(posicao)
    posicao_anterior = @posicoes[posicao_index - 1]
    posicao_anterior.total_geral(corretora) + _movimentacoes_mes(posicao, corretora)
  end

  def _posicoes(data_desde, intervalo)
    lista = []
    data_ate = Utils.ultimo_dia_util Date.today

    until data_desde.month == data_ate.month do
      ca = Posicao.new(@carteira, data_ate)
      lista.push ca
      data_ate = data_ate.prev_month.end_of_month
    end

    lista.reverse
  end

end