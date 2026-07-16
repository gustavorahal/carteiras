class ProjetarEventoFinanceiro
  Resultado = Data.define(:estado, :resultados_operacoes)

  ZERO = BigDecimal("0")

  def self.call(estado:, evento:)
    new(estado, evento).call
  end

  def initialize(estado, evento)
    @estado = estado.to_h.transform_values { |posicao| posicao.to_h.transform_values { |valor| valor } }
    @evento = evento
    @resultados = []
  end

  def call
    case @evento.tipo
    when "operacao" then aplicar_operacao(@evento.operacao)
    when "transferencia_custodia" then aplicar_transferencia(@evento.transferencia_custodia)
    when "evento_corporativo" then aplicar_evento_corporativo(@evento.evento_corporativo)
    end
    quantizar!
    Resultado.new(estado: @estado, resultados_operacoes: @resultados)
  end

  private

  def posicao(chave)
    @estado[chave] ||= {
      quantidade: ZERO, custo_total: ZERO, custo_total_base: ZERO,
      resultado_realizado: ZERO, ultimo_evento_id: nil
    }
  end

  def aplicar_operacao(operacao)
    chave = [operacao.conta_investimento_id, operacao.ativo_id]
    atual = posicao(chave)
    delta = operacao.compra? ? operacao.quantidade : -operacao.quantidade
    negociacao = calcular_negociacao(
      quantidade_atual: atual[:quantidade], custo_atual: atual[:custo_total], delta: delta,
      preco: operacao.preco_unitario, custos: operacao.custos_operacionais
    )
    base = calcular_negociacao(
      quantidade_atual: atual[:quantidade], custo_atual: atual[:custo_total_base], delta: delta,
      preco: operacao.preco_unitario * operacao.taxa_conversao_base,
      custos: operacao.custos_operacionais * operacao.taxa_conversao_base
    )

    atual.merge!(
      quantidade: negociacao[:quantidade], custo_total: negociacao[:custo],
      custo_total_base: base[:custo],
      resultado_realizado: atual[:resultado_realizado] + base[:resultado],
      ultimo_evento_id: @evento.id
    )

    return if negociacao[:quantidade_encerrada].zero?

    @resultados << {
      operacao_id: operacao.id,
      quantidade_encerrada: negociacao[:quantidade_encerrada],
      custo_alocado: base[:custo_alocado],
      valor_alienacao: base[:valor_alienacao],
      custos_alocados: base[:custos_alocados],
      resultado_realizado: base[:resultado]
    }
  end

  def calcular_negociacao(quantidade_atual:, custo_atual:, delta:, preco:, custos:)
    if quantidade_atual.zero? || mesma_direcao?(quantidade_atual, delta)
      return abertura(quantidade_atual, custo_atual, delta, preco, custos)
    end

    quantidade_encerrada = [quantidade_atual.abs, delta.abs].min
    proporcao_encerrada = quantidade_encerrada / delta.abs
    custos_encerramento = custos * proporcao_encerrada
    custo_medio = custo_atual.abs / quantidade_atual.abs
    custo_alocado = custo_medio * quantidade_encerrada
    valor_negociado = preco * quantidade_encerrada

    resultado = if quantidade_atual.positive?
      valor_negociado - custos_encerramento - custo_alocado
    else
      custo_alocado - valor_negociado - custos_encerramento
    end

    quantidade_final = quantidade_atual + delta
    custo_final = if quantidade_final.zero?
      ZERO
    elsif mesma_direcao?(quantidade_final, quantidade_atual)
      (quantidade_atual.positive? ? 1 : -1) * custo_medio * quantidade_final.abs
    else
      custos_abertura = custos - custos_encerramento
      custo_de_abertura(quantidade_final, preco, custos_abertura)
    end

    {
      quantidade: quantidade_final, custo: custo_final, resultado: resultado,
      quantidade_encerrada: quantidade_encerrada, custo_alocado: custo_alocado,
      valor_alienacao: valor_negociado, custos_alocados: custos_encerramento
    }
  end

  def abertura(quantidade_atual, custo_atual, delta, preco, custos)
    {
      quantidade: quantidade_atual + delta,
      custo: custo_atual + custo_de_abertura(delta, preco, custos),
      resultado: ZERO, quantidade_encerrada: ZERO, custo_alocado: ZERO,
      valor_alienacao: ZERO, custos_alocados: ZERO
    }
  end

  def custo_de_abertura(quantidade, preco, custos)
    bruto = preco * quantidade.abs
    if quantidade.negative? && custos >= bruto
      raise ArgumentError, "Custos devem ser menores que o valor bruto ao abrir posição vendida"
    end
    quantidade.positive? ? bruto + custos : -(bruto - custos)
  end

  def mesma_direcao?(a, b) = (a.positive? && b.positive?) || (a.negative? && b.negative?)

  def aplicar_transferencia(transferencia)
    origem = posicao([transferencia.conta_origem_id, transferencia.ativo_id])
    raise ArgumentError, "Quantidade de custódia indisponível na origem" if origem[:quantidade].zero? || transferencia.quantidade > origem[:quantidade].abs

    sinal = origem[:quantidade].positive? ? 1 : -1
    quantidade_movida = transferencia.quantidade * sinal
    proporcao = transferencia.quantidade / origem[:quantidade].abs
    custo_movido = origem[:custo_total] * proporcao
    custo_base_movido = origem[:custo_total_base] * proporcao
    destino = posicao([transferencia.conta_destino_id, transferencia.ativo_id])
    if !destino[:quantidade].zero? && !mesma_direcao?(destino[:quantidade], quantidade_movida)
      raise ArgumentError, "Transferência de custódia não pode cruzar uma posição oposta no destino"
    end

    origem[:quantidade] -= quantidade_movida
    origem[:custo_total] -= custo_movido
    origem[:custo_total_base] -= custo_base_movido
    origem[:custo_total] = origem[:custo_total_base] = ZERO if origem[:quantidade].zero?
    origem[:ultimo_evento_id] = @evento.id

    destino[:quantidade] += quantidade_movida
    destino[:custo_total] += custo_movido
    destino[:custo_total_base] += custo_base_movido
    destino[:ultimo_evento_id] = @evento.id
  end

  def aplicar_evento_corporativo(evento)
    origem = posicao([evento.conta_investimento_id, evento.ativo_origem_id])
    raise ArgumentError, "Não há posição para aplicar o evento corporativo" if origem[:quantidade].zero?

    if evento.incorporacao?
      aplicar_incorporacao(evento, origem)
    else
      quantidade = evento.quantidade_final || origem[:quantidade].abs * evento.fator
      origem[:quantidade] = origem[:quantidade].negative? ? -quantidade : quantidade
      origem[:ultimo_evento_id] = @evento.id
    end
  end

  def aplicar_incorporacao(evento, origem)
    destino = posicao([evento.conta_investimento_id, evento.ativo_destino_id])
    nova_quantidade = evento.quantidade_final || origem[:quantidade] * evento.fator
    nova_quantidade *= -1 if origem[:quantidade].negative? && nova_quantidade.positive?
    if !destino[:quantidade].zero? && !mesma_direcao?(destino[:quantidade], nova_quantidade)
      raise ArgumentError, "Incorporação não pode cruzar posição oposta no ativo de destino"
    end

    custo_transferido = origem[:custo_total]
    custo_base_transferido = origem[:custo_total_base]
    resultado_transferido = origem[:resultado_realizado]
    if evento.realizar_fracao?
      raise ArgumentError, "Fração em dinheiro de posição vendida não é suportada" if origem[:quantidade].negative?
      proporcao = evento.percentual_custo_fracao / 100
      custo_base_fracao = custo_base_transferido.abs * proporcao
      custo_transferido *= 1 - proporcao
      custo_base_transferido *= 1 - proporcao
      resultado_transferido += evento.valor_fracao * evento.taxa_conversao_base - custo_base_fracao
    end

    destino[:quantidade] += nova_quantidade
    destino[:custo_total] += custo_transferido
    destino[:custo_total_base] += custo_base_transferido
    destino[:resultado_realizado] += resultado_transferido
    destino[:ultimo_evento_id] = @evento.id
    origem.merge!(quantidade: ZERO, custo_total: ZERO, custo_total_base: ZERO,
      resultado_realizado: ZERO, ultimo_evento_id: @evento.id)
  end

  def quantizar!
    @estado.each_value do |valores|
      valores[:quantidade] = valores[:quantidade].round(10, BigDecimal::ROUND_HALF_UP)
      %i[custo_total custo_total_base resultado_realizado].each do |campo|
        valores[campo] = valores[campo].round(12, BigDecimal::ROUND_HALF_UP)
      end
    end
    @resultados.each do |resultado|
      resultado[:quantidade_encerrada] = resultado[:quantidade_encerrada].round(10, BigDecimal::ROUND_HALF_UP)
      %i[custo_alocado valor_alienacao custos_alocados resultado_realizado].each do |campo|
        resultado[campo] = resultado[campo].round(12, BigDecimal::ROUND_HALF_UP)
      end
    end
  end
end
