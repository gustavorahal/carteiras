class ReconstruirPosicoesCarteira
  ASSOCIACOES = %i[operacao provento movimentacao_caixa transferencia_caixa transferencia_custodia evento_corporativo].freeze

  def self.call(carteira:, ate: nil, persistir: true)
    new(carteira, ate, persistir).call
  end

  def initialize(carteira, ate, persistir)
    @carteira = carteira
    @ate = ate
    @persistir = persistir
  end

  def call
    return calcular_e_persistir unless @persistir

    Carteira.transaction do
      @carteira.lock!
      calcular_e_persistir
    end
  end

  private

  def calcular_e_persistir
    eventos = @carteira.eventos_financeiros.confirmado
    eventos = eventos.where(data_competencia: ..@ate) if @ate
    eventos = eventos.includes(*ASSOCIACOES).ordenados_para_replay.to_a
    revertidos = eventos.filter_map { |evento| evento.evento_revertido_id if evento.reversao? }.to_set
    estado = {}
    resultados = []

    eventos.each do |evento|
      next if evento.reversao? || revertidos.include?(evento.id)
      projetado = ProjetarEventoFinanceiro.call(estado: estado, evento: evento)
      estado = projetado.estado
      resultados.concat(projetado.resultados_operacoes)
    end

    persistir!(estado, resultados) if @persistir
    estado
  end

  def persistir!(estado, resultados)
    agora = Time.current
    escopo = PosicaoAtual.where(conta_investimento_id: @carteira.contas_investimento.select(:id))
    nova_versao = escopo.maximum(:versao).to_i + 1
    escopo.delete_all
    linhas = estado.map do |(conta_id, ativo_id), valores|
      valores.slice(:quantidade, :custo_total, :custo_total_base, :resultado_realizado).merge(
        conta_investimento_id: conta_id, ativo_id: ativo_id,
        ultimo_evento_aplicado_id: valores[:ultimo_evento_id], versao: nova_versao,
        created_at: agora, updated_at: agora
      )
    end
    PosicaoAtual.insert_all!(linhas) if linhas.any?

    operacoes = Operacao.joins(:evento_financeiro).where(eventos_financeiros: { carteira_id: @carteira.id })
    ResultadoOperacao.where(operacao_id: operacoes.select(:id)).delete_all
    ResultadoOperacao.insert_all!(resultados.map { |r| r.merge(created_at: agora, updated_at: agora) }) if resultados.any?
  end
end
