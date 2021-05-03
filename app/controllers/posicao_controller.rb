class PosicaoController < ApplicationController

  before_action :set_vars, only: [:index, :show]

  def index
    authorize @posicao
    @view = params[:view]

    set_vars_view_atual_vs_ref if @view == 'atual_vs_ref'
  end

  def show
    authorize @posicao
    @posicao_ativo = PosicaoAtivo.new(params[:carteira_id], params[:ativo_id], @data)
    @ativo = @posicao_ativo.ativo
  end


  private

  def set_vars
    @carteira = Carteira.find params[:carteira_id]
    @posicao = Posicao.new(@carteira, @data)
    @posicao_referencia = PosicaoReferencia.new(@posicao)
    @porcentagens_por_book_carteira = @posicao_referencia.porcentagens_por_book
    @valor_por_book_carteira = @posicao_referencia.valor_por_book
    @contas_correntes = ContaCorrente.includes(:corretora).where(carteira_id: @carteira.id)
    @porcentagens_por_book_ref = @carteira.referencia.porcentagens_por_book
    @ativos_posicao_por_book = @posicao_referencia.ativos_posicao_por_book
  end

  def set_vars_view_atual_vs_ref
    @referencia_ativos_por_book = @carteira.referencia.referencia_ativos_por_book
    @carteira_lista_de_ativos = @posicao.ativos
    @posicao_restante = @carteira_lista_de_ativos.clone
  end

end