class ConfirmarEventoFinanceiro
  def self.call(evento) = new(evento).call

  def initialize(evento)
    @evento = evento
  end

  def call
    return @evento if @evento.confirmado?

    EventoFinanceiro.transaction do
      @evento.carteira.with_lock do
        @evento.lock!
        return @evento if @evento.confirmado?
        validar_detalhe!
        reconstruir = reconstruir_posicoes?
        @evento.sequencia_na_data ||= proxima_sequencia
        @evento.send(:confirmacao_em_curso=, true)
        begin
          @evento.estado = :confirmado
          @evento.save!
          criar_lancamentos_caixa!
          if reconstruir
            ReconstruirPosicoesCarteira.call(carteira: @evento.carteira)
          else
            AplicarEventoFinanceiroAtual.call(@evento)
          end
          InvalidarResumosDiariosCarteira.call(carteiras: [@evento.carteira], inicio: @evento.data_competencia)
        ensure
          @evento.send(:confirmacao_em_curso=, false)
        end
      end
    end
    @evento
  end

  private

  def proxima_sequencia
    @evento.carteira.eventos_financeiros
      .where(data_competencia: @evento.data_competencia).maximum(:sequencia_na_data).to_i + 1
  end

  def reconstruir_posicoes?
    @evento.reversao? || @evento.carteira.eventos_financeiros.confirmado
      .where("data_competencia > ?", @evento.data_competencia).exists?
  end

  def validar_detalhe!
    return validar_reversao! if @evento.reversao?
    detalhe = @evento.detalhe
    raise ActiveRecord::RecordInvalid, @evento unless detalhe

    contas = case detalhe
    when Operacao, Provento, EventoCorporativo then [detalhe.conta_investimento]
    when MovimentacaoCaixa then [detalhe.conta_caixa.conta_investimento]
    when TransferenciaCaixa then [detalhe.conta_caixa_origem.conta_investimento, detalhe.conta_caixa_destino.conta_investimento]
    when TransferenciaCustodia then [detalhe.conta_origem, detalhe.conta_destino]
    end
    unless contas.all? { |conta| conta.carteira_id == @evento.carteira_id }
      @evento.errors.add(:base, "Todas as contas devem pertencer à carteira do evento")
      raise ActiveRecord::RecordInvalid, @evento
    end
    raise ActiveRecord::RecordInvalid, detalhe unless detalhe.valid?
  end

  def validar_reversao!
    original = @evento.evento_revertido
    if original.blank? || !original.confirmado? || original.revertido? || original.carteira_id != @evento.carteira_id
      @evento.errors.add(:evento_revertido, "deve ser um evento confirmado, não revertido e da mesma carteira")
      raise ActiveRecord::RecordInvalid, @evento
    end
    if @evento.data_competencia != original.data_competencia
      @evento.errors.add(:data_competencia, "deve preservar a competência econômica do evento original")
      raise ActiveRecord::RecordInvalid, @evento
    end
  end

  def criar_lancamentos_caixa!
    case @evento.tipo
    when "operacao" then lancamento_operacao
    when "provento" then lancamento_provento
    when "movimentacao_caixa" then lancamento_movimentacao
    when "transferencia_caixa" then lancamentos_transferencia
    when "evento_corporativo" then lancamento_fracao
    when "reversao" then lancamentos_reversao
    end
  end

  def conta_caixa!(conta_investimento, moeda)
    conta_investimento.contas_caixa.find_by!(moeda: moeda)
  end

  def criar_lancamento!(conta:, data:, natureza:, valor:)
    return if valor.zero?
    @evento.lancamentos_caixa.create!(conta_caixa: conta, data_efetiva: data, natureza: natureza, valor: valor)
  end

  def lancamento_operacao
    operacao = @evento.operacao
    valor = operacao.compra? ? -(operacao.valor_bruto + operacao.custos_operacionais) : operacao.valor_bruto - operacao.custos_operacionais
    criar_lancamento!(conta: conta_caixa!(operacao.conta_investimento, operacao.moeda),
      data: operacao.data_liquidacao, natureza: operacao.natureza, valor: valor)
  end

  def lancamento_provento
    provento = @evento.provento
    criar_lancamento!(conta: conta_caixa!(provento.conta_investimento, provento.moeda),
      data: provento.data_pagamento, natureza: provento.tipo, valor: provento.valor_liquido)
  end

  def lancamento_movimentacao
    movimento = @evento.movimentacao_caixa
    valor = movimento.entrada? ? movimento.valor : -movimento.valor
    criar_lancamento!(conta: movimento.conta_caixa, data: movimento.data_efetiva,
      natureza: movimento.natureza, valor: valor)
  end

  def lancamentos_transferencia
    transferencia = @evento.transferencia_caixa
    criar_lancamento!(conta: transferencia.conta_caixa_origem, data: transferencia.data_efetiva,
      natureza: "transferencia_saida", valor: -transferencia.valor)
    criar_lancamento!(conta: transferencia.conta_caixa_destino, data: transferencia.data_efetiva,
      natureza: "transferencia_entrada", valor: transferencia.valor)
  end

  def lancamento_fracao
    corporativo = @evento.evento_corporativo
    return unless corporativo.valor_fracao&.positive?
    criar_lancamento!(conta: conta_caixa!(corporativo.conta_investimento, corporativo.moeda),
      data: @evento.data_competencia, natureza: "fracao", valor: corporativo.valor_fracao)
  end

  def lancamentos_reversao
    @evento.evento_revertido.lancamentos_caixa.find_each do |original|
      criar_lancamento!(conta: original.conta_caixa, data: original.data_efetiva,
        natureza: "reversao_#{original.id}", valor: -original.valor)
    end
  end
end
