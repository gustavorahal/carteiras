class CotacoesController < ApplicationController

  def index_all
    # por enqunato não temos paginação, então limitar
    @cotacoes = policy_scope(Cotacao).includes(:ativo).order(data: :desc).limit(400)
    authorize Cotacao, :index?
  end

  def index
    @ativo = policy_scope(Ativo).find params[:ativo_id]
    @cotacoes = policy_scope(@ativo.cotacoes).includes(:ativo).order(data: :desc)
  end

  def new
    @ativo = policy_scope(Ativo).find params[:ativo_id]
    @cotacao = Cotacao.new
    authorize @cotacao
  end

  def create
    @ativo = policy_scope(Ativo).find params[:ativo_id]
    @cotacao = @ativo.cotacoes.new secure_params
    authorize @cotacao

    if @cotacao.save
      redirect_to ativo_cotacoes_path ativo_id: params[:ativo_id]
    else
      render 'new'
    end
  end

  def edit
    @ativo = policy_scope(Ativo).find params[:ativo_id]
    @cotacao = policy_scope(@ativo.cotacoes).find params[:id]
    authorize @cotacao
  end

  def update
    @ativo = policy_scope(Ativo).find params[:ativo_id]
    @cotacao = policy_scope(@ativo.cotacoes).find params[:id]
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
