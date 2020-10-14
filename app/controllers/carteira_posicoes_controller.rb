class CarteiraPosicoesController < ApplicationController

  before_action :set_vars, only: [:index, :show]

  def index
    @view = params[:view]
  end

  def show
    @carteira_ativo_posicao = CarteiraAtivoPosicao.new(params[:id], @data)
    @carteira_ativo = @carteira_ativo_posicao.carteira_ativo
  end

  private

  def set_vars
    @carteira = Carteira.find params[:carteira_id]
    @carteira_posicao = CarteiraPosicao.new(@carteira, @data)
    @carteira_posicao_caps = @carteira_posicao.carteira_ativos_posicoes
    @carteira_ativos = @carteira.carteira_ativos_por_book
  end

end