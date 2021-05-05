class MovimentacoesController < ApplicationController

  def index
    @carteira = Carteira.find params[:carteira_id]
    @mes_a_mes = @carteira.movimentacoes.mes_a_mes
    @movimentacoes = @carteira.movimentacoes.includes(:corretora).order(data: :asc)
    authorize @movimentacoes.take
    @total = @carteira.movimentacoes.total
  end

end