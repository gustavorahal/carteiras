class CarteirasController < ApplicationController
  def index
    @carteiras = policy_scope(Carteira).ativas.order(:nome)
  end

  def show
    @carteira = policy_scope(Carteira).find(params[:id])
    authorize @carteira
    @posicao = ConsultarPosicaoCarteira.call(carteira: @carteira, data: @data)
  end

  def posicao_historica
    @carteira = policy_scope(Carteira).find(params[:carteira_id])
    authorize @carteira, :show?
    @estado = ConsultarPosicaoHistorica.call(carteira: @carteira, data: @data)
  end

  def rentabilidade
    @carteira = policy_scope(Carteira).find(params[:carteira_id])
    authorize @carteira, :show?
    @rentabilidade = ConsultarRentabilidade.call(carteira: @carteira,
      inicio: params[:inicio]&.to_date || @data.beginning_of_year, fim: @data)
  end

  def comparacao_referencia
    @carteira = policy_scope(Carteira).find(params[:carteira_id])
    authorize @carteira, :show?
    @referencias = policy_scope(Referencia).order(:nome)
    return unless params[:referencia_id].present?
    @referencia = @referencias.find(params[:referencia_id])
    @comparacao = ConsultarComparacaoReferencia.call(carteira: @carteira,
      referencia: @referencia, data: @data)
  end
end
