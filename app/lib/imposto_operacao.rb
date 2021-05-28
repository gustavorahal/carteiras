class ImpostoOperacao

  attr_reader :ativo

  def initialize(operacao)
    @operacao = operacao
    @carteira = operacao.carteira
    @ativo = operacao.ativo
    @usdbrl_valor = CotacaoService.moedas('USDBRL', @operacao.data).valor_unit

    raise StandardError, "Operação ID #{operacao.id} não tributável" if operacao.operacao != 'V' || !@ativo.tipo.in?(Ativo.tipos_bolsa)

    @cap = PosicaoAtivo.new(@carteira, @ativo, operacao.data)
    @data_inicio = @cap.data_montagem
    @data_fim = operacao.data

  end

  def custos_operacionais
    @carteira.operacoes
             .where(ativo_id: @ativo.id)
             .where(data: @data_inicio..@data_fim)
             .sum('(co_taxa + co_emolumentos + co_corretagem + co_iss_iof + co_irrf + co_outros) * usdbrl')
  end

  def quantidade_vendida
    @operacao.quantidade.negative? ? @operacao.quantidade * -1 : @operacao.quantidade
  end

  def data_montagem
    @cap.data_montagem
  end

  def data_venda
    @operacao.data
  end

  def preco_medio_compra
    @cap.preco_medio_em_brl
  end

  def valor_venda
    if @ativo.usd?
      @operacao.valor_unit * quantidade_vendida * @usdbrl_valor
    else
      @operacao.valor_unit * quantidade_vendida
    end
  end

  def preco_venda
    if @ativo.usd?
      @operacao.valor_unit * @usdbrl_valor
    else
      @operacao.valor_unit
    end
  end

  def lucro_bruto
    valor_venda - (preco_medio_compra * quantidade_vendida)
  end

  def lucro_liquido
    lucro_bruto - custos_operacionais
  end

  def imposto_a_pagar
    lucro_liquido * Impostos.porcentagem_imposto(@ativo.tipo, @ativo.moeda)
  end

end