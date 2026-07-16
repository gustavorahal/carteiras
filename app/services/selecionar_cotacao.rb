class SelecionarCotacao
  def self.ativo(ativo:, data:, buscadores:)
    FonteCotacao.ativas.each do |fonte|
      next unless fonte.tipos_atendidos.include?("ativo") || fonte.tipos_atendidos.include?(ativo.tipo)
      buscador = buscadores[fonte.nome] || buscadores[fonte.id]
      next unless buscador
      preco = buscador.call(ativo, data)
      next unless preco&.positive?
      cotacao = CotacaoAtivo.find_or_initialize_by(ativo:, data:)
      cotacao.update!(preco:, moeda: ativo.moeda_negociacao, fonte_cotacao: fonte, manual: false,
        usuario_responsavel: nil)
      invalidar_resumos(data)
      return cotacao
    end
    nil
  end

  def self.corrigir_ativo(ativo:, data:, preco:, fonte:, usuario:)
    cotacao = CotacaoAtivo.find_or_initialize_by(ativo:, data:)
    cotacao.update!(preco:, moeda: ativo.moeda_negociacao, fonte_cotacao: fonte,
      manual: true, usuario_responsavel: usuario)
    invalidar_resumos(data)
    cotacao
  end

  def self.cambio(moeda_origem:, moeda_destino:, data:, buscadores:)
    FonteCotacao.ativas.each do |fonte|
      next unless fonte.tipos_atendidos.include?("cambio")
      buscador = buscadores[fonte.nome] || buscadores[fonte.id]
      next unless buscador
      taxa = buscador.call(moeda_origem, moeda_destino, data)
      next unless taxa&.positive?
      cotacao = CotacaoCambio.find_or_initialize_by(moeda_origem:, moeda_destino:, data:)
      cotacao.update!(taxa:, fonte_cotacao: fonte, manual: false, usuario_responsavel: nil)
      invalidar_resumos(data)
      return cotacao
    end
    nil
  end

  def self.corrigir_cambio(moeda_origem:, moeda_destino:, data:, taxa:, fonte:, usuario:)
    cotacao = CotacaoCambio.find_or_initialize_by(moeda_origem:, moeda_destino:, data:)
    cotacao.update!(taxa:, fonte_cotacao: fonte, manual: true, usuario_responsavel: usuario)
    invalidar_resumos(data)
    cotacao
  end

  def self.invalidar_resumos(data)
    carteiras = Carteira.joins(:resumos_diarios).where(resumos_diarios_carteira: { data: data.. }).distinct
    InvalidarResumosDiariosCarteira.call(carteiras:, inicio: data)
  end
  private_class_method :invalidar_resumos
end
