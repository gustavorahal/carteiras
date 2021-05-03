class ProventosController < ApplicationController

  def index
    @carteira = Carteira.find params[:carteira_id]
    @proventos = @carteira.proventos.includes(:corretora, :ativo).order(data: :asc)
    @total = @carteira.proventos.sum :valor_liquido
    @mes_a_mes_total = @carteira.proventos.mes_a_mes
    @mes_a_mes_dividendo = @carteira.proventos.mes_a_mes('dividendo')
    @mes_a_mes_rendimento = @carteira.proventos.mes_a_mes('rendimento')
    @mes_a_mes_jcp = @carteira.proventos.mes_a_mes('jcp')

    @total_fii_mes_a_mes = {}
    # vamos limitar aos ultimos 6 meses, para ficar menos pesado e tb
    # a API free da marketstack só tem histórico de 1 ano
    data_max = Date.today - 6.month
    @mes_a_mes_rendimento.each do |mes, valor|
      next if mes < data_max

      ca = Posicao.new(@carteira, mes)
      @total_fii_mes_a_mes[mes] = 0 unless @total_fii_mes_a_mes.key? mes
      @total_fii_mes_a_mes[mes] += ca.total_fii
    end
  end

end