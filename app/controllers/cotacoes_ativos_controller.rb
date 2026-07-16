class CotacoesAtivosController < ApplicationController
  def index
    authorize Ativo, :index?
    @cotacoes = CotacaoAtivo.includes(:ativo, :moeda, :fonte_cotacao).order(data: :desc)
  end

  def new
    authorize Ativo, :update?
    @cotacao = CotacaoAtivo.new(data: Date.current)
    carregar_formulario
  end

  def create
    authorize Ativo, :update?
    ativo = Ativo.find(cotacao_params[:ativo_id])
    fonte = FonteCotacao.find(cotacao_params[:fonte_cotacao_id])
    SelecionarCotacao.corrigir_ativo(ativo:, data: cotacao_params[:data], preco: cotacao_params[:preco],
      fonte:, usuario: current_user)
    redirect_to cotacoes_ativos_path, notice: "Cotação canônica atualizada."
  rescue ActiveRecord::RecordInvalid, ArgumentError => e
    @cotacao = CotacaoAtivo.new(cotacao_params)
    carregar_formulario
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
  end

  private

  def carregar_formulario
    @ativos = Ativo.ativos.order(:codigo)
    @fontes = FonteCotacao.ativas.order(:prioridade, :nome)
  end

  def cotacao_params = params.require(:cotacao_ativo).permit(:ativo_id, :data, :preco, :fonte_cotacao_id)
end
