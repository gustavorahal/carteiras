class ContaCorrentesController < ApplicationController

  before_action :set_vars, only: [:index, :new, :create, :edit, :update]

  def index
    @conta_correntes = policy_scope(@carteira.conta_correntes).includes(:corretora)
  end

  def show
    @carteira = policy_scope(Carteira).find params[:carteira_id]
    @conta_corrente = policy_scope(@carteira.conta_correntes).find params[:id]
    authorize @conta_corrente
    @extratos = @conta_corrente.extratos_data(@data)
  end

  def new
    @conta_corrente = ContaCorrente.new
    authorize @carteira
  end

  def create
    @conta_corrente = @carteira.conta_correntes.new secure_params.except(:carteira_id)
    authorize @conta_corrente

    if @conta_corrente.save
      redirect_to carteira_conta_corrente_path(@carteira, @conta_corrente)
    else
      render 'new'
    end
  end

  def edit
    @conta_corrente = policy_scope(@carteira.conta_correntes).find params[:id]
    authorize @conta_corrente
  end

  def update
    @conta_corrente = policy_scope(@carteira.conta_correntes).find params[:id]
    authorize @conta_corrente
    if @conta_corrente.update(secure_params)
      redirect_to carteira_conta_corrente_path(@carteira, @conta_corrente),
                                          notice: "Conta Corrente atualizada com sucesso!"
    else
      render 'edit'
    end
  end

  private

  def set_vars
    @corretoras = Corretora.all.order(:nome)
    @carteira = policy_scope(Carteira).find params[:carteira_id]
  end

  def secure_params
    params.require(:conta_corrente).permit(:corretora_id, :carteira_id, :moeda)
  end

end
