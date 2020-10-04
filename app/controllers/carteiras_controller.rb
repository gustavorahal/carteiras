class CarteirasController < ApplicationController

  def index
    @carteiras = Carteira.all
  end

  def show
    @carteira = Carteira.find params[:id]
    @contas_correntes = ContaCorrente.includes(:corretora).where(investidor_id: @carteira.investidor.id)
    @carteira_posicao = CarteiraPosicao.new(@carteira, @data)
  end

end