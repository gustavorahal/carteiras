class AplicarEventoFinanceiroAtual
  TIPOS_COM_POSICAO = %w[operacao transferencia_custodia evento_corporativo].freeze

  def self.call(evento)
    return unless evento.tipo.in?(TIPOS_COM_POSICAO)
    new(evento).call
  end

  def initialize(evento)
    @evento = evento
  end

  def call
    registros = PosicaoAtual.joins(:conta_investimento)
      .where(contas_investimento: { carteira_id: @evento.carteira_id }).to_a
    estado = registros.index_by { |p| [p.conta_investimento_id, p.ativo_id] }.transform_values do |p|
      { quantidade: p.quantidade, custo_total: p.custo_total, custo_total_base: p.custo_total_base,
        resultado_realizado: p.resultado_realizado, ultimo_evento_id: p.ultimo_evento_aplicado_id }
    end
    anterior = estado.deep_dup
    resultado = ProjetarEventoFinanceiro.call(estado:, evento: @evento)
    chaves_alteradas = resultado.estado.keys.select { |chave| anterior[chave] != resultado.estado[chave] }

    chaves_alteradas.each do |conta_id, ativo_id|
      valores = resultado.estado.fetch([conta_id, ativo_id])
      posicao = registros.find { |p| p.conta_investimento_id == conta_id && p.ativo_id == ativo_id }
      posicao ||= PosicaoAtual.new(conta_investimento_id: conta_id, ativo_id: ativo_id, versao: 0)
      posicao.update!(valores.slice(:quantidade, :custo_total, :custo_total_base, :resultado_realizado).merge(
        ultimo_evento_aplicado_id: valores[:ultimo_evento_id], versao: posicao.versao + 1
      ))
    end

    resultado.resultados_operacoes.each { |atributos| ResultadoOperacao.create!(atributos) }
  end
end
