class CarteirasController < ApplicationController

  def index
    @carteiras = Carteira.all
  end

  def show
    data_fim = Date.today
    @carteira = Carteira.find params[:id]
    @carteira_posicao = CarteiraPosicao.new(@carteira, data_fim)
    @carteira_ativos = @carteira.carteira_ativos.where(valido: true).order(:book)
    true
  end

end