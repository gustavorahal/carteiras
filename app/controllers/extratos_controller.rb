class ExtratosController < ApplicationController

  before_action :set_vars, only: [:new, :create, :edit, :update, :destroy]

  def import
    cc = policy_scope(ContaCorrente).find params[:conta_corrente_id]
    authorize cc
    carteira = cc.carteira
    extrato_file = params[:file]
    begin
      Extratos::Importa.importar(cc, extrato_file.path)
      Extratos::Processa.processar(cc)
      redirect_to carteira_conta_corrente_path(carteira, cc), notice: 'Extrato importado e processado com sucesso'
    rescue StandardError => e
      redirect_to carteira_conta_corrente_path(carteira, cc), alert: e.message
    end
  end

  def new
    @extrato = Extrato.new
  end

  def create
    @extrato = Extrato.new secure_params

    if @extrato.save
      redirect_to carteira_conta_corrente_path(@carteira, @conta_corrente)
    else
      render 'new'
    end
  end

  def edit
    @extrato = @conta_corrente.extratos.find params[:id]
  end

  def update
    @extrato = @conta_corrente.extratos.find params[:id]

    if @extrato.update(secure_params)
      redirect_to carteira_conta_corrente_path(@carteira, @conta_corrente)
    else
      render 'edit'
    end
  end

  def destroy
    @extrato = @conta_corrente.extratos.find params[:id]
    @extrato.destroy
    redirect_to request.referrer || carteira_conta_corrente_path(@carteira, @conta_corrente)
  end

  private

  def secure_params
    params.require(:extrato).permit(:liquidacao, :movimentacao, :descricao, :valor, :saldo, :file, :conta_corrente_id)
  end

  def set_vars
    @conta_corrente = policy_scope(ContaCorrente).find params[:conta_corrente_id]
    authorize @conta_corrente
    @carteira = @conta_corrente.carteira
  end

end
