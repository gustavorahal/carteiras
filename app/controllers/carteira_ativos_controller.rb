class CarteiraAtivosController < ApplicationController

  before_action :set_vars, only: [:index, :show]

  def index
    @view = params[:view]

    set_vars_view_atual_vs_ref if @view == 'atual_vs_ref'
    set_vars_view_book if @view == 'book'
  end

  def show
    @ativo_posicao = AtivoPosicao.new(params[:carteira_id], params[:ativo_id], @data)
    @ativo = @ativo_posicao.ativo
  end


  private

  def set_vars
    @carteira = Carteira.find params[:carteira_id]
    @carteira_ativos = CarteiraPosicao.new(@carteira, @data)
    @carteira_ativos_referencia = CarteiraAtivosReferencia.new(@carteira_ativos)
    @porcentagens_por_book_carteira = @carteira_ativos_referencia.porcentagens_por_book
    @valor_por_book_carteira = @carteira_ativos_referencia.valor_por_book
  end

  def set_vars_view_book
    @ativos_posicao_por_book = @carteira_ativos_referencia.ativos_posicao_por_book
  end

  def set_vars_view_atual_vs_ref
    @referencia_ativos_por_book = @carteira.referencia.ativos_por_book
    @carteira_lista_de_ativos = @carteira_ativos.ativos
    @carteira_ativos_restante = @carteira_lista_de_ativos.clone
    @porcentagens_por_book_ref = @carteira.referencia.porcentagens_por_book
  end

end