class EventosFinanceirosController < ApplicationController
  TIPOS_CADASTRAVEIS = %w[operacao provento movimentacao_caixa transferencia_caixa
    transferencia_custodia evento_corporativo].freeze

  before_action :set_carteira
  before_action :set_evento, only: %i[show confirmar reverter destroy]

  def index
    @eventos = policy_scope(@carteira.eventos_financeiros).includes(:reversao)
      .ordenados_para_replay.reverse_order
  end

  def show
    authorize @evento
  end

  def new
    authorize @carteira, :update?
    @tipo = params[:tipo].presence_in(TIPOS_CADASTRAVEIS) || "operacao"
    carregar_formulario
  end

  def create
    authorize @carteira, :update?
    @evento = RegistrarEventoFinanceiro.call(carteira: @carteira, usuario: current_user,
      tipo: tipo_evento, atributos: detalhe_params.to_h.symbolize_keys,
      data_competencia: evento_params[:data_competencia], observacao: evento_params[:observacao],
      chave_idempotencia: evento_params[:chave_idempotencia], confirmar: false)
    redirect_to carteira_eventos_financeiro_path(@carteira, @evento), notice: "Rascunho criado com sucesso."
  rescue ActiveRecord::RecordInvalid, ArgumentError => e
    @tipo = params.dig(:evento_financeiro, :tipo).presence_in(TIPOS_CADASTRAVEIS) || "operacao"
    carregar_formulario
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
  end

  def confirmar
    authorize @evento, :confirmar?
    ConfirmarEventoFinanceiro.call(@evento)
    redirect_to carteira_eventos_financeiro_path(@carteira, @evento), notice: "Evento confirmado."
  end

  def reverter
    authorize @evento, :reverter?
    reversao = ReverterEventoFinanceiro.call(evento: @evento, usuario: current_user,
      observacao: params[:observacao])
    redirect_to carteira_eventos_financeiro_path(@carteira, reversao), notice: "Evento revertido."
  end

  def destroy
    authorize @evento
    ExcluirEventoFinanceiroRascunho.call(@evento)
    redirect_to carteira_eventos_financeiros_path(@carteira), notice: "Rascunho excluído."
  end

  private

  def set_carteira = @carteira = policy_scope(Carteira).find(params[:carteira_id])
  def set_evento
    @evento = policy_scope(@carteira.eventos_financeiros)
      .includes(:reversao, :operacao, :provento, :movimentacao_caixa, :transferencia_caixa,
        :transferencia_custodia, :evento_corporativo).find(params[:id])
  end

  def evento_params
    params.require(:evento_financeiro).permit(:tipo, :data_competencia,
      :observacao, :chave_idempotencia)
  end

  def tipo_evento
    evento_params.fetch(:tipo).tap do |tipo|
      raise ArgumentError, "Tipo de evento não pode ser cadastrado diretamente" unless tipo.in?(TIPOS_CADASTRAVEIS)
    end
  end

  def carregar_formulario
    @contas = @carteira.contas_investimento.ativas.includes(contas_caixa: :moeda).order(:nome)
    @contas_caixa = @contas.flat_map(&:contas_caixa)
    @ativos = Ativo.ativos.order(:codigo, :mercado)
    @moedas = Moeda.ativas.order(:codigo)
  end

  def detalhe_params
    params.require(:detalhe).permit(
      :conta_investimento_id, :conta_caixa_id, :conta_caixa_origem_id, :conta_caixa_destino_id,
      :conta_origem_id, :conta_destino_id, :ativo_id, :ativo_origem_id, :ativo_destino_id,
      :natureza, :direcao, :tipo, :quantidade, :quantidade_referencia, :quantidade_final,
      :preco_unitario, :moeda_id, :data_negociacao, :data_liquidacao, :data_base,
      :data_pagamento, :data_efetiva, :valor, :valor_bruto, :tributos, :valor_liquido,
      :taxa, :emolumentos, :corretagem, :iss_iof, :irrf, :outros,
      :taxa_conversao_base, :taxa_conversao_fiscal, :fator, :valor_fracao,
      :percentual_custo_fracao, :regra_alocacao_custo
    )
  end
end
