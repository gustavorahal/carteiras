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
    @carteira = policy_scope(Carteira).find params[:carteira_id]
    @posicao = Posicao.new(@carteira, @data)
    @contas_correntes = policy_scope(@carteira.conta_correntes).includes(:corretora)

    if @carteira.referencia.present?
      @posicao_referencia = PosicaoReferencia.new(@posicao)
      @porcentagens_por_book_carteira = @posicao_referencia.porcentagens_por_book
      @valor_por_book_carteira = @posicao_referencia.valor_por_book
      @porcentagens_por_book_ref = @carteira.referencia.porcentagens_por_book
      @ativos_posicao_por_book = @posicao_referencia.ativos_posicao_por_book
    else
      set_vars_sem_referencia
    end
  end

  def set_vars_view_atual_vs_ref
    unless @carteira.referencia.present?
      @view = "book"
      flash.now[:alert] = "Carteira sem referência cadastrada; exibindo posição por tipo de ativo."
      return
    end

    @referencia_ativos_por_book = @carteira.referencia.referencia_ativos_por_book
    @carteira_lista_de_ativos = @posicao.ativos
    @posicao_restante = @carteira_lista_de_ativos.clone
  end

  def set_vars_sem_referencia
    @posicao_referencia = nil
    @porcentagens_por_book_ref = {}
    @ativos_posicao_por_book = @posicao.posicao_ativos.group_by { |posicao_ativo| posicao_ativo.ativo.tipo.upcase }
    @valor_por_book_carteira = @ativos_posicao_por_book.transform_values do |posicao_ativos|
      posicao_ativos.sum(&:valor_em_brl)
    end
    total = @posicao.total_geral
    @porcentagens_por_book_carteira = @valor_por_book_carteira.transform_values do |valor|
      total.zero? ? 0 : (valor / total) * 100
    end
  end

end
