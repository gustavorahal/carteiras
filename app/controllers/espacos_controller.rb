class EspacosController < ApplicationController
  before_action :carregar_espaco_por_id, only: %i[show edit update arquivar restaurar]

  def index
    @espacos = policy_scope(Espaco).order(:nome)
  end

  def show
    authorize @espaco
  end

  def new
    @espaco = Espaco.new
    authorize @espaco
  end

  def create
    @espaco = Espaco.new(espaco_params)
    authorize @espaco
    Espaco.transaction do
      @espaco.save!
      @espaco.adicionar_primeiro_administrador!(current_user)
    end
    redirect_to @espaco, notice: "Espaço criado."
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_content
  end

  def edit = authorize(@espaco)

  def update
    authorize @espaco
    @espaco.update!(espaco_params)
    redirect_to @espaco, notice: "Espaço atualizado."
  rescue ActiveRecord::RecordInvalid
    render :edit, status: :unprocessable_content
  end

  def arquivar
    authorize @espaco, :arquivar?
    @espaco.arquivar!
    redirect_to espacos_path, notice: "Espaço arquivado."
  end

  def restaurar
    authorize @espaco, :restaurar?
    @espaco.restaurar!
    redirect_to @espaco, notice: "Espaço restaurado."
  end

  private

  def carregar_espaco_por_id = @espaco = policy_scope(Espaco).find(params[:id])
  def espaco_params = params.require(:espaco).permit(:nome)
end
