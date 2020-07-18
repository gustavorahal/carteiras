class CarteiraAtivosController < ApplicationController

  def index
    @carteira = Carteira.find params[:carteira_id]
    @carteira_ativos = CarteiraAtivo.joins(:ativo).where(carteira_id: @carteira.id, valido: true).order(:book)
    @books_porcentagem = CarteiraAtivo.where(carteira: @carteira.id, valido: true).group(:book).order(:book).sum(:porcentagem)
  end
end