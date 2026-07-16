class ConsultarResultadosEconomicos
  Linha = Data.define(:resultado, :operacao, :ativo, :categoria, :casos_nao_suportados)

  def self.call(carteira:, ano: Date.current.year)
    periodo = Date.new(ano).all_year
    resultados = ResultadoOperacao.includes(operacao: [:ativo, :moeda, :conta_investimento, { evento_financeiro: :carteira }])
      .joins(operacao: :evento_financeiro)
      .where(eventos_financeiros: { carteira_id: carteira.id, data_competencia: periodo })
      .order("eventos_financeiros.data_competencia", "resultados_operacoes.id").to_a
    operacoes = Operacao.joins(:evento_financeiro)
      .where(eventos_financeiros: { carteira_id: carteira.id }, data_negociacao: periodo)
      .pluck(:conta_investimento_id, :ativo_id, :data_negociacao, :natureza)
    naturezas = operacoes.group_by { |conta_id, ativo_id, data, _| [conta_id, ativo_id, data] }
      .transform_values { |linhas| linhas.map(&:last).uniq }

    linhas = resultados.map do |resultado|
      operacao = resultado.operacao
      casos = []
      chave = [operacao.conta_investimento_id, operacao.ativo_id, operacao.data_negociacao]
      casos << "day trade" if naturezas.fetch(chave, []).sort == %w[compra venda]
      casos << "cobertura de posição vendida" if operacao.compra?
      Linha.new(resultado:, operacao:, ativo: operacao.ativo,
        categoria: "#{operacao.ativo.tipo} / #{operacao.moeda.codigo}", casos_nao_suportados: casos)
    end
    { linhas:, total_resultado: resultados.sum(&:resultado_realizado),
      aviso: "Resultado econômico por custo médio; não é apuração tributária. Isenções, compensações, day trade e regimes especiais não são calculados." }
  end
end
