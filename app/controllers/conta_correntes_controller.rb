class ContaCorrentesController < ApplicationController

  def index
    @carteira = Carteira.find params[:carteira_id]
    @conta_correntes = ContaCorrente.includes(:corretora).where(carteira: @carteira)
  end

  def show
    @conta_corrente = ContaCorrente.find params[:id]
    @extratos = @conta_corrente.extratos.where("liquidacao::date <= '#{@data}'").order(liquidacao: :desc)
    @carteira = @conta_corrente.carteira
  end

end
