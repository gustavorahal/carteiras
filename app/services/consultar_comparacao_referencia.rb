class ConsultarComparacaoReferencia
  def self.call(carteira:, referencia:, data: Date.current)
    versao = referencia.versao_vigente_em(data)
    return { versao: nil, comparacoes: [], posicao: [], completa: false } unless versao

    estado = ConsultarPosicaoHistorica.call(carteira:, data:)
    chaves = estado.select { |_chave, valores| !valores[:quantidade].zero? }.keys
    ativos = Ativo.where(id: chaves.map(&:last).uniq).index_by(&:id)
    cotacoes = CotacaoAtivo.where(ativo_id: ativos.keys, data: ..data)
      .select("DISTINCT ON (ativo_id) cotacoes_ativos.*").order(:ativo_id, data: :desc).index_by(&:ativo_id)
    moedas = ativos.values.map(&:moeda_negociacao_id).uniq - [carteira.moeda_base_id]
    cambios = CotacaoCambio.where(moeda_origem_id: moedas, moeda_destino_id: carteira.moeda_base_id, data: ..data)
      .select("DISTINCT ON (moeda_origem_id) cotacoes_cambio.*")
      .order(:moeda_origem_id, data: :desc).index_by(&:moeda_origem_id)

    completa = true
    posicao = chaves.map do |conta_id, ativo_id|
      ativo = ativos.fetch(ativo_id)
      cotacao = cotacoes[ativo_id]
      cambio = cambios[ativo.moeda_negociacao_id]
      taxa = ativo.moeda_negociacao_id == carteira.moeda_base_id ? 1.to_d : cambio&.taxa
      completa = false unless cotacao && taxa
      valor_base = cotacao && taxa && estado[[conta_id, ativo_id]][:quantidade] * cotacao.preco * taxa
      { conta_investimento_id: conta_id, ativo:, quantidade: estado[[conta_id, ativo_id]][:quantidade], valor_base: }
    end
    valores = posicao.group_by { |item| item[:ativo].id }
      .transform_values { |itens| itens.sum { |item| item[:valor_base].to_d } }
    total = valores.values.sum
    comparacoes = versao.alocacoes.includes(:ativo).map do |alocacao|
      percentual_atual = completa && total.nonzero? ? valores.fetch(alocacao.ativo_id, 0.to_d) / total * 100 : nil
      { alocacao:, percentual_atual:, diferenca: percentual_atual && percentual_atual - alocacao.percentual }
    end
    { versao:, comparacoes:, posicao:, completa: completa && total.nonzero? }
  end
end
