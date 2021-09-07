class CotacoesController < ApplicationController

  def index_all
    # por enqunato não temos paginação, então limitar
    @cotacoes = Cotacao.includes(:ativo).order(data: :desc).limit(400)
    authorize @cotacoes.take
  end

  def index
    @ativo = Ativo.find params[:ativo_id]
    @cotacoes = Cotacao.where(ativo_id: @ativo.id).includes(:ativo).order(data: :desc)
    authorize Cotacao
  end

  def new
    @ativo = Ativo.find params[:ativo_id]
    @cotacao = Cotacao.new
    authorize @cotacao
  end

  def create
    @ativo = Ativo.find params[:ativo_id]
    @cotacao = Cotacao.new secure_params
    @cotacao.ativo = @ativo
    authorize @cotacao

    if @cotacao.save
      redirect_to ativo_cotacoes_path ativo_id: params[:ativo_id]
    else
      render 'new'
    end
  end

  def edit
    @ativo = Ativo.find params[:ativo_id]
    @cotacao = Cotacao.find params[:id]
    authorize @cotacao
  end

  def update
    @cotacao = Cotacao.find params[:id]
    authorize @cotacao
    if @cotacao.update(secure_params)
      redirect_to ativo_cotacoes_path ativo_id: params[:ativo_id], notice: "Cotação atualizada com sucesso!"
    else
      render 'edit'
    end
  end


  private

  def secure_params
    params.require(:cotacao).permit(:valor_unit, :data)
  end

end