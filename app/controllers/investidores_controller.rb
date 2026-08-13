class InvestidoresController < ApplicationController
  before_action :carregar_espaco
  before_action :carregar_investidor, only: %i[edit update arquivar restaurar]

  def new
    @investidor = @espaco.investidores.new
    authorize @investidor
  end

  def create
    @investidor = @espaco.investidores.new(investidor_params)
    authorize @investidor
    @investidor.save!
    redirect_to @espaco, notice: "Investidor criado."
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_content
  end

  def edit = authorize(@investidor)

  def update
    authorize @investidor
    @investidor.update!(investidor_params)
    redirect_to @espaco, notice: "Investidor atualizado."
  rescue ActiveRecord::RecordInvalid
    render :edit, status: :unprocessable_content
  end

  def arquivar
    authorize @investidor, :arquivar?
    @investidor.arquivar!
    redirect_to @espaco
  end

  def restaurar
    authorize @investidor, :restaurar?
    @investidor.restaurar!
    redirect_to @espaco
  end

  private

  def carregar_investidor = @investidor = @espaco.investidores.find(params[:id])
  def investidor_params = params.require(:investidor).permit(:nome)
end
