class ContaCorrentesController < ApplicationController

  def index
    @investidor = Investidor.find params[:investidor_id]
    @conta_correntes = ContaCorrente.includes(:corretora).where(investidor: @investidor)
  end

  def show
    @data = if params[:data].present?
              params[:data].to_date
            else
              Date.today
            end
    @conta_corrente = ContaCorrente.find params[:id]
    @extratos = @conta_corrente.extratos.where("liquidacao <= '#{@data}'").order(liquidacao: :desc)
    @investidor = @conta_corrente.investidor
  end


end
