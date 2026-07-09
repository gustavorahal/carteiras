class ReferenciasController < ApplicationController

  def index
    @referencias = policy_scope(Referencia).order(:nome)
    authorize Referencia, :index?
  end

  def show
    @referencia = policy_scope(Referencia).find params[:id]
    authorize @referencia
    @porcentagens_por_book_ref = @referencia.porcentagens_por_book
  end

end
