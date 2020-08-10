class CarteiraAtivosController < ApplicationController

  def show
    @carteira_ativo = CarteiraAtivo.includes(:operacoes, :ativo).find(params[:id])
  end

end