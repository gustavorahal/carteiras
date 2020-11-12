class ImpostosController < ApplicationController

  def index
    @carteira = Carteira.find params[:carteira_id]
    @tributacao_acoes = Impostos.tributacao_mes_a_mes(@carteira, @data.year, :acao)
    @tributacao_fii = Impostos.tributacao_mes_a_mes(@carteira, @data.year, :fii)
  end

end