class ImpostosController < ApplicationController

  def ganho_de_capital
    @carteira = Carteira.find params[:carteira_id]
    authorize @carteira
    @tributacao_acoes_brl = Impostos.tributacao_mes_a_mes(@carteira, @data.year, %w[acao etf], 'BRL')
    @tributacao_fii_brl = Impostos.tributacao_mes_a_mes(@carteira, @data.year, ['fii'], 'BRL')
    @tributacao_usd = Impostos.tributacao_mes_a_mes(@carteira, @data.year, %w[acao etf fii], 'USD')
  end

  def posicao_ano_anterior
    @carteira = Carteira.find params[:carteira_id]
    authorize @carteira
    @data = Date.new(Date.today.year - 1, 12, 31) # data ano anterior
    @posicao = Posicao.new(@carteira, @data)
  end

end