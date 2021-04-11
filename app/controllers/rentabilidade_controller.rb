class RentabilidadeController < ApplicationController

  def index
    @carteira = Carteira.find params[:carteira_id]
    @ultimos_carteira_ativos = []
    corretoras_tmp = []
    ultimo_dia_mes_anterior = Date.today.prev_month.end_of_month
    # ultimos 8 meses para não pesar
    8.times do
      ca = CarteiraAtivos.new(@carteira, ultimo_dia_mes_anterior)
      @ultimos_carteira_ativos.push ca
      ultimo_dia_mes_anterior = ultimo_dia_mes_anterior.prev_month.end_of_month
      corretoras_tmp += ca.corretoras
    end
    @corretoras = corretoras_tmp.uniq

    # queremos ordem ascendente para que o calcula da rentabilidade mês
    # a mês funcione corretamente
    @ultimos_carteira_ativos = @ultimos_carteira_ativos.reverse
  end

end