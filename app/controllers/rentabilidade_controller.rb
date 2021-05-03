class RentabilidadeController < ApplicationController

  def index
    @carteira = Carteira.find params[:carteira_id]
    @ultimos_posicao = []
    corretoras_tmp = []
    ate_dia_do_mes = Utils.ultimo_dia_util Date.today
    # ultimos 8 meses para não pesar
    8.times do
      ca = Posicao.new(@carteira, ate_dia_do_mes)
      @ultimos_posicao.push ca
      ate_dia_do_mes = ate_dia_do_mes.prev_month.end_of_month
      corretoras_tmp += ca.corretoras
    end
    @corretoras = corretoras_tmp.uniq

    # queremos ordem ascendente para que o calcula da rentabilidade mês
    # a mês funcione corretamente
    @ultimos_posicao = @ultimos_posicao.reverse
  end

end