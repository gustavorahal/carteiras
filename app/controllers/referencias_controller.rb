class ReferenciasController < ApplicationController

  def index
    @referencias = Referencia.all.order(:nome)
  end

  def show
    @referencia = Referencia.find params[:id]
    @porcentagens_por_book_ref = @referencia.porcentagens_por_book
  end

end