class CarteirasController < ApplicationController

  def index
    @carteiras = policy_scope(Carteira)
  end

end
