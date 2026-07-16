class RegistrarEventoFinanceiro
  DATAS = {
    operacao: :data_negociacao, provento: :data_pagamento, movimentacao_caixa: :data_efetiva,
    transferencia_caixa: :data_efetiva
  }.freeze

  def self.call(carteira:, usuario:, tipo:, atributos:, origem: :manual, chave_idempotencia: nil,
    data_competencia: nil, observacao: nil, confirmar: true)
    new(carteira:, usuario:, tipo:, atributos:, origem:, chave_idempotencia:,
      data_competencia:, observacao:, confirmar:).call
  end

  def initialize(**opcoes)
    @carteira = opcoes.fetch(:carteira)
    @usuario = opcoes.fetch(:usuario)
    @tipo = opcoes.fetch(:tipo).to_sym
    @atributos = opcoes.fetch(:atributos)
    @origem = opcoes.fetch(:origem)
    @chave = opcoes[:chave_idempotencia].presence
    @data = opcoes[:data_competencia]
    @observacao = opcoes[:observacao]
    @confirmar = opcoes.fetch(:confirmar)
  end

  def call
    existente = buscar_existente
    return existente if existente

    EventoFinanceiro.transaction(requires_new: true) do
      @carteira.lock!
      existente = buscar_existente
      return existente if existente
      evento = EventoFinanceiro.create!(carteira: @carteira, usuario_responsavel: @usuario,
        tipo: @tipo, origem: @origem, estado: :rascunho, data_competencia: competencia,
        chave_idempotencia: @chave, observacao: @observacao)
      evento.public_send("create_#{@tipo}!", @atributos)
      ValidarPropriedadeEvento.call(evento)
      @confirmar ? ConfirmarEventoFinanceiro.call(evento) : evento
    end
  rescue ActiveRecord::RecordNotUnique
    buscar_existente || raise
  end

  private

  def buscar_existente
    return if @chave.blank?
    evento = @carteira.eventos_financeiros.find_by(chave_idempotencia: @chave)
    raise ArgumentError, "Chave de idempotência já usada por outro tipo de evento" if evento && evento.tipo != @tipo.to_s
    evento
  end

  def competencia
    @data || @atributos[DATAS[@tipo]] || @atributos[:data_competencia] || Date.current
  end
end
