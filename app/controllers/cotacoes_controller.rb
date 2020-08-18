class CotacoesController < ApplicationController

  def index
    @ativo = Ativo.find params[:ativo_id]
    @cotacoes = Cotacao.where(ativo_id: @ativo.id).includes(:ativo).order(data: :desc)
  end

  def new
    @ativo = Ativo.find params[:ativo_id]
    @cotacao = Cotacao.new
  end

  def create
    @ativo = Ativo.find params[:ativo_id]
    @cotacao = Cotacao.new secure_params
    @cotacao.ativo = @ativo

    if @cotacao.save
      redirect_to ativo_cotacoes_path ativo_id: params[:ativo_id]
    else
      render 'new'
    end
  end

  private

  def secure_params
    params.require(:cotacao).permit(:valor_unit, :data)
  end

end