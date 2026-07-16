class ConsultarPosicaoCarteira
  Item = Data.define(:posicao, :cotacao, :data_cotacao, :cotacao_defasada,
    :data_cambio, :cambio_defasado, :valor, :valor_base, :completa)
  Resultado = Data.define(:itens, :saldos_caixa, :data)

  def self.call(carteira:, data: Date.current)
    new(carteira, data).call
  end

  def initialize(carteira, data)
    @carteira = carteira
    @data = data
  end

  def call
    posicoes = PosicaoAtual.eager_load(:ativo, conta_investimento: :corretora)
      .where(contas_investimento: { carteira_id: @carteira.id })
      .to_a
    cotacoes = cotacoes_para(posicoes.map(&:ativo_id))
    taxas = taxas_para(posicoes.map { |p| p.ativo.moeda_negociacao_id }.uniq)
    itens = posicoes.map { |posicao| montar_item(posicao, cotacoes[posicao.ativo_id], taxas) }
    Resultado.new(itens:, saldos_caixa: ConsultarSaldosCaixa.call(carteira: @carteira, data: @data), data: @data)
  end

  private

  def cotacoes_para(ativos)
    return {} if ativos.empty?
    CotacaoAtivo.where(ativo_id: ativos, data: ..@data)
      .select("DISTINCT ON (ativo_id) cotacoes_ativos.*")
      .order(:ativo_id, data: :desc).index_by(&:ativo_id)
  end

  def taxas_para(moedas)
    destino = @carteira.moeda_base_id
    CotacaoCambio.where(moeda_origem_id: moedas, moeda_destino_id: destino, data: ..@data)
      .select("DISTINCT ON (moeda_origem_id) cotacoes_cambio.*")
      .order(:moeda_origem_id, data: :desc).index_by(&:moeda_origem_id)
  end

  def montar_item(posicao, cotacao, taxas)
    return Item.new(posicao:, cotacao: nil, data_cotacao: nil, cotacao_defasada: false,
      data_cambio: nil, cambio_defasado: false, valor: nil, valor_base: nil, completa: false) unless cotacao

    valor = posicao.quantidade * cotacao.preco
    cambio = taxas[posicao.ativo.moeda_negociacao_id]
    taxa = posicao.ativo.moeda_negociacao_id == @carteira.moeda_base_id ? 1.to_d : cambio&.taxa
    Item.new(posicao:, cotacao: cotacao.preco, data_cotacao: cotacao.data,
      cotacao_defasada: cotacao.data < @data, data_cambio: cambio&.data,
      cambio_defasado: cambio.present? && cambio.data < @data,
      valor:, valor_base: taxa && valor * taxa, completa: taxa.present?)
  end
end
