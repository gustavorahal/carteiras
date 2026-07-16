class RecalcularResumosDiarios
  def self.call(carteira:, inicio:, fim: Date.current)
    new(carteira, inicio, fim).call
  end

  def initialize(carteira, inicio, fim)
    @carteira = carteira
    @inicio = inicio
    @fim = fim
  end

  def call
    ResumoDiarioCarteira.transaction do
      anterior = @carteira.resumos_diarios.where("data < ?", @inicio).order(data: :desc).first
      (@inicio..@fim).each do |data|
        resumo = calcular_dia(data, anterior&.patrimonio_final)
        anterior = @carteira.resumos_diarios.find_or_initialize_by(data:)
        anterior.update!(resumo)
      end
    end
  end

  private

  def calcular_dia(data, patrimonio_inicial)
    estado = ConsultarPosicaoHistorica.call(carteira: @carteira, data:)
    valor_ativos, data_ativos, completo = valorizar(estado, data)
    saldos = ConsultarSaldosCaixa.call(carteira: @carteira, data:)
    valor_caixa, data_caixa = converter_caixa(saldos, data)
    completo &&= valor_caixa.present?
    patrimonio_final = completo ? valor_ativos + valor_caixa : nil
    fluxo = fluxo_externo(data)
    twr = if patrimonio_inicial&.nonzero? && patrimonio_final
      (patrimonio_final - fluxo) / patrimonio_inicial - 1
    end
    estado_completude = if !completo
      :incompleto
    elsif patrimonio_inicial.blank? || patrimonio_inicial.zero?
      :sem_patrimonio_inicial
    else
      :completo
    end
    {
      patrimonio_inicial:, patrimonio_final:, valor_ativos: completo ? valor_ativos : nil,
      valor_caixa:, fluxo_externo_liquido: fluxo,
      resultado_diario: patrimonio_final && patrimonio_inicial ? patrimonio_final - patrimonio_inicial - fluxo : nil,
      twr_diario: twr, data_cotacoes_usadas: [data_ativos, data_caixa].compact.min, estado_completude:
    }
  end

  def valorizar(estado, data)
    chaves = estado.select { |_chave, p| !p[:quantidade].zero? }.keys
    return [0.to_d, data, true] if chaves.empty?
    ativos = Ativo.where(id: chaves.map(&:last).uniq).index_by(&:id)
    cotacoes = CotacaoAtivo.where(ativo_id: ativos.keys, data: ..data)
      .select("DISTINCT ON (ativo_id) cotacoes_ativos.*").order(:ativo_id, data: :desc).index_by(&:ativo_id)
    moedas = ativos.values.map(&:moeda_negociacao_id).uniq
    taxas = CotacaoCambio.where(moeda_origem_id: moedas, moeda_destino_id: @carteira.moeda_base_id, data: ..data)
      .select("DISTINCT ON (moeda_origem_id) cotacoes_cambio.*").order(:moeda_origem_id, data: :desc).index_by(&:moeda_origem_id)
    datas = []
    total = chaves.sum do |(_conta_id, ativo_id)|
      ativo = ativos.fetch(ativo_id)
      cotacao = cotacoes[ativo_id]
      return [nil, nil, false] unless cotacao
      cambio = taxas[ativo.moeda_negociacao_id]
      taxa = ativo.moeda_negociacao_id == @carteira.moeda_base_id ? 1.to_d : cambio&.taxa
      return [nil, nil, false] unless taxa
      datas << cotacao.data
      datas << cambio.data if cambio
      estado[[_conta_id, ativo_id]][:quantidade] * cotacao.preco * taxa
    end
    [total, datas.min, true]
  end

  def converter_caixa(saldos, data)
    contas = ContaCaixa.includes(:moeda).where(id: saldos.keys).index_by(&:id)
    moedas = contas.values.map(&:moeda_id).uniq - [@carteira.moeda_base_id]
    taxas = CotacaoCambio.where(moeda_origem_id: moedas, moeda_destino_id: @carteira.moeda_base_id, data: ..data)
      .select("DISTINCT ON (moeda_origem_id) cotacoes_cambio.*")
      .order(:moeda_origem_id, data: :desc).index_by(&:moeda_origem_id)
    datas = []
    total = saldos.sum do |conta_id, saldo|
      conta = contas.fetch(conta_id)
      next saldo if conta.moeda_id == @carteira.moeda_base_id
      cambio = taxas[conta.moeda_id]
      return [nil, nil] unless cambio
      datas << cambio.data
      saldo * cambio.taxa
    end
    [total, datas.min]
  end

  def fluxo_externo(data)
    LancamentoCaixa.joins(conta_caixa: :conta_investimento)
      .where(contas_investimento: { carteira_id: @carteira.id }, data_efetiva: data,
        natureza: %w[aporte resgate]).sum(:valor)
  end
end
