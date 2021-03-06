class CarteirasController < ApplicationController

  def index
    @carteiras = Carteira.all
  end

end