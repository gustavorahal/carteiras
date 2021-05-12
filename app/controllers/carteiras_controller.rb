class CarteirasController < ApplicationController

  def index
    @carteiras = Carteira.all
    @carteiras.each { |carteira| authorize carteira }
  end

end