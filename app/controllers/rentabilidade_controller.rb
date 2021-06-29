class RentabilidadeController < ApplicationController

  def index
    @carteira = Carteira.find params[:carteira_id]
    authorize @carteira

    # ultimos 7 meses para não pesar
    rent = Rentabilidade.new(@carteira, Date.today - 7.month)
    @mes_a_mes_corretoras = rent.mes_a_mes_corretoras
    @mes_a_mes_global = rent.mes_a_mes_global
    @corretoras = rent.corretoras
  end

end