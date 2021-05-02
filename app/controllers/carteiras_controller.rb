class CarteirasController < ApplicationController

  def index
    @carteiras = Carteira.all
    authorize @carteiras
  end

end