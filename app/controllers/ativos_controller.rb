class AtivosController < ApplicationController

  def index
    @ativos = policy_scope(Ativo).order(created_at: :desc)
  end

  def new
    @ativo = Ativo.new
    authorize @ativo
  end

  def create
    @ativo = Ativo.new secure_params
    authorize @ativo

    if @ativo.save
      redirect_to ativos_path
    else
      render 'new'
    end
  end

  def edit
    @ativo = policy_scope(Ativo).find params[:id]
    authorize @ativo
  end

  def update
    @ativo = policy_scope(Ativo).find params[:id]
    authorize @ativo

    if @ativo.update(secure_params)
      redirect_to ativos_path, notice: "Ativo #{@ativo.nome_amigavel} atualizado com sucesso!"
    else
      render 'edit'
    end
  end

  private

  def secure_params
    params.require(:ativo).permit(:nome, :descricao, :moeda_negociacao, :moeda_exposicao, :tipo, :cnpj)
  end

end
