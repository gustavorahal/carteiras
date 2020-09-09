class CarteiraPosicoesController < ApplicationController

  before_action :set_vars, only: [:index, :show]

  def index
    @view = params[:view]
  end

  def show
    @carteira_ativo = CarteiraAtivo.includes(:operacoes, :ativo).find(params[:id])
  end

  private

  def set_vars
    @data_fim = Date.today
    @carteira = Carteira.find params[:carteira_id]
    @carteira_posicao = CarteiraPosicao.new(@carteira, @data_fim)
    @carteira_ativos_posicao = @carteira_posicao.carteira_ativos
    @carteira_ativos = @carteira.carteira_ativos.where(valido: true).order(:book).order('ativos.nome')
  end

end