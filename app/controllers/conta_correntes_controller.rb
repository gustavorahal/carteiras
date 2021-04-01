class ContaCorrentesController < ApplicationController

  before_action :set_vars, only: [:index, :new, :create, :edit, :update]

  def index
    @conta_correntes = ContaCorrente.includes(:corretora).where(carteira: @carteira)
  end

  def show
    @conta_corrente = ContaCorrente.find params[:id]
    @extratos = @conta_corrente.extratos.where("movimentacao::date <= '#{@data}'").order(movimentacao: :desc, created_at: :desc)
    @carteira = @conta_corrente.carteira
    @saldo_por_extrato_id = @conta_corrente.saldo_por_extrato_id
  end

  def new
    @conta_corrente = ContaCorrente.new
  end

  def create
    @conta_corrente = ContaCorrente.new secure_params

    if @conta_corrente.save
      redirect_to carteira_conta_corrente_path(@carteira, @conta_corrente)
    else
      render 'new'
    end
  end

  def edit
    @conta_corrente = ContaCorrente.find params[:id]
  end

  def update
    @conta_corrente = ContaCorrente.find params[:id]
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
    @carteira = Carteira.find params[:carteira_id]
  end

  def secure_params
    params.require(:conta_corrente).permit(:corretora_id, :carteira_id, :moeda)
  end

end
