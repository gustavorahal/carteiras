class RelatoriosController < ApplicationController
  before_action :set_carteira

  def resultados_economicos
    authorize @carteira, :show?
    @ano = params[:ano].presence&.to_i || @data.year
    @relatorio = ConsultarResultadosEconomicos.call(carteira: @carteira, ano: @ano)
  end

  def posicao_ano_anterior
    authorize @carteira, :show?
    @data = Date.new((params[:ano].presence&.to_i || Date.current.year) - 1, 12, 31)
    @estado = ConsultarPosicaoHistorica.call(carteira: @carteira, data: @data)
    @contas = @carteira.contas_investimento.includes(:corretora).index_by(&:id)
    @ativos = Ativo.where(id: @estado.keys.map(&:last).uniq).index_by(&:id)
  end

  private

  def set_carteira = @carteira = policy_scope(Carteira).find(params[:carteira_id])
end
