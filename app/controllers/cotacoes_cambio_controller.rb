class CotacoesCambioController < ApplicationController
  def index
    authorize Ativo, :index?
    @cotacoes = CotacaoCambio.includes(:moeda_origem, :moeda_destino, :fonte_cotacao)
      .order(data: :desc)
  end

  def new
    authorize Ativo, :update?
    @cotacao = CotacaoCambio.new(data: Date.current)
    carregar_formulario
  end

  def create
    authorize Ativo, :update?
    SelecionarCotacao.corrigir_cambio(
      moeda_origem: Moeda.find(cotacao_params[:moeda_origem_id]),
      moeda_destino: Moeda.find(cotacao_params[:moeda_destino_id]),
      data: cotacao_params[:data], taxa: cotacao_params[:taxa],
      fonte: FonteCotacao.find(cotacao_params[:fonte_cotacao_id]), usuario: current_user
    )
    redirect_to cotacoes_cambio_index_path, notice: "Cotação de câmbio atualizada."
  rescue ActiveRecord::RecordInvalid, ArgumentError => e
    @cotacao = CotacaoCambio.new(cotacao_params)
    carregar_formulario
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
  end

  private

  def carregar_formulario
    @moedas = Moeda.ativas.order(:codigo)
    @fontes = FonteCotacao.ativas.order(:prioridade, :nome)
  end

  def cotacao_params
    params.require(:cotacao_cambio).permit(:moeda_origem_id, :moeda_destino_id, :data,
      :taxa, :fonte_cotacao_id)
  end
end
