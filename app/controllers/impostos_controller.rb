class ImpostosController < ApplicationController

  def index
    @carteira = Carteira.find params[:carteira_id]
    @tributacao_acoes_brl = Impostos.tributacao_mes_a_mes(@carteira, @data.year, %w[acao etf], 'BRL')
    @tributacao_fii_brl = Impostos.tributacao_mes_a_mes(@carteira, @data.year, ['fii'], 'BRL')
    @tributacao_usd = Impostos.tributacao_mes_a_mes(@carteira, @data.year, %w[acao etf fii], 'USD')
  end

end