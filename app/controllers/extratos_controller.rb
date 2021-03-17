class ExtratosController < ApplicationController

  def import
    cc = ContaCorrente.find params[:conta_corrente_id]
    carteira = cc.carteira
    extrato_file = params[:file]
    begin
      ImportaExtrato.importar(cc, extrato_file.path)
      redirect_to carteira_conta_corrente_path(carteira, cc), notice: 'Extrato importado com sucesso'
    rescue StandardError => e
      redirect_to carteira_conta_corrente_path(carteira, cc), alert: e.message
    end
  end

  def new
    @extrato = Extrato.new
    @conta_corrente = ContaCorrente.find params[:conta_corrente_id]
    @investidor = @conta_corrente.investidor
  end

  def create
    @extrato = Extrato.new secure_params
    @conta_corrente = ContaCorrente.find params[:conta_corrente_id]
    @carteira = @conta_corrente.carteira

    if @extrato.save
      redirect_to carteira_conta_corrente_path(@carteira, @conta_corrente)
    else
      render 'new'
    end
  end

  private

  def secure_params
    params.require(:extrato).permit(:liquidacao, :movimentacao, :descricao, :valor, :file, :conta_corrente_id)
  end

end