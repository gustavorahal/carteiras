class AtivosController < ApplicationController
  before_action :set_ativo, only: %i[show edit update destroy]
  before_action :carregar_moedas, only: %i[new create edit update]

  def index = @ativos = policy_scope(Ativo).ativos.includes(:moeda_negociacao).order(:codigo)
  def show = authorize(@ativo)

  def new
    @ativo = Ativo.new
    authorize @ativo
  end

  def create
    @ativo = Ativo.new(ativo_params)
    authorize @ativo
    @ativo.save! and redirect_to ativos_path, notice: "Ativo criado."
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  def edit = authorize(@ativo)

  def update
    authorize @ativo
    @ativo.update!(ativo_params)
    redirect_to ativos_path, notice: "Ativo atualizado."
  rescue ActiveRecord::RecordInvalid
    render :edit, status: :unprocessable_entity
  end

  def destroy
    authorize @ativo
    @ativo.update!(arquivado_em: Time.current)
    redirect_to ativos_path, notice: "Ativo arquivado."
  end

  private

  def set_ativo = @ativo = policy_scope(Ativo).find(params[:id])
  def carregar_moedas = @moedas = Moeda.ativas.order(:codigo)
  def ativo_params = params.require(:ativo).permit(:codigo, :mercado, :descricao, :tipo, :moeda_negociacao_id, :moeda_exposicao_id, :cnpj)
end
