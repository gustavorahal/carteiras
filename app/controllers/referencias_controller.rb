class ReferenciasController < ApplicationController
  before_action :set_referencia, only: %i[show edit update destroy]

  def index
    authorize Referencia, :index?
    @referencias = Referencia.includes(:versoes).order(:nome)
  end

  def show
    authorize @referencia
    @versoes = @referencia.versoes.order(vigencia_inicial: :desc)
  end

  def new
    @referencia = Referencia.new
    authorize @referencia
  end

  def create
    @referencia = Referencia.new(referencia_params)
    authorize @referencia
    @referencia.save!
    redirect_to @referencia, notice: "Referência criada."
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  def edit = authorize(@referencia)

  def update
    authorize @referencia
    @referencia.update!(referencia_params)
    redirect_to @referencia, notice: "Referência atualizada."
  rescue ActiveRecord::RecordInvalid
    render :edit, status: :unprocessable_entity
  end

  def destroy
    authorize @referencia
    @referencia.destroy!
    redirect_to referencias_path, notice: "Referência excluída."
  end

  private

  def set_referencia = @referencia = Referencia.find(params[:id])
  def referencia_params = params.require(:referencia).permit(:nome, :descricao)
end
