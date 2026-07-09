class MovimentacoesController < ApplicationController

  def index
    @carteira = policy_scope(Carteira).find params[:carteira_id]
    @mes_a_mes = @carteira.movimentacoes.mes_a_mes
    @movimentacoes = policy_scope(@carteira.movimentacoes).includes(:extrato).order(data: :asc)
    @total = @carteira.movimentacoes.total
  end

end
