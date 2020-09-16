class CarteirasController < ApplicationController

  def index
    @carteiras = Carteira.all
  end

  def show
    @view = params[:view].to_i
    @data_fim = Date.today
    @carteira = Carteira.find params[:id]
    @contas_correntes = ContaCorrente.includes(:corretora).where(investidor_id: @carteira.investidor.id)
    @carteira_posicao = CarteiraPosicao.new(@carteira, @data_fim)
    @carteira_ativos_posicao = @carteira_posicao.carteira_ativos
    @carteira_ativos = @carteira.carteira_ativos_validos_por_book
    carteira_ativos_soma_tmp = @carteira_ativos_posicao.union(@carteira_ativos)
    # reordena por book
    @carteira_ativos_soma = {}
    carteira_ativos_soma_tmp.each do |ca|
      @carteira_ativos_soma[ca.book] = [] unless ca.book.in? @carteira_ativos_soma
      @carteira_ativos_soma[ca.book].push ca
    end
  end

end