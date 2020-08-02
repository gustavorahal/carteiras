class CarteirasController < ApplicationController

  def index
    @carteiras = Carteira.all
  end

  def show
    data_fim = Date.today.strftime '%F'
    @carteira = Carteira.find params[:id]
    @carteira_posicao = CarteiraPosicao.new(@carteira, data_fim)
  end

end