class CarteirasController < ApplicationController

  def index
    @carteiras = Carteira.all
  end

  def show
    @data = if params[:data].present?
              params[:data].to_date
            else
              Date.today
            end
    @carteira = Carteira.find params[:id]
    @contas_correntes = ContaCorrente.includes(:corretora).where(investidor_id: @carteira.investidor.id)
    @carteira_posicao = CarteiraPosicao.new(@carteira, @data)
  end

end