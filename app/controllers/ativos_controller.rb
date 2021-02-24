class AtivosController < ApplicationController

  def index
    @ativos = Ativo.all.order(created_at: :desc)
  end

  def new
    @ativo = Ativo.new
  end

  def create
    @ativo = Ativo.new secure_params

    if @ativo.save
      redirect_to ativos_path
    else
      render 'new'
    end

  end

  def edit
    @ativo = Ativo.find params[:id]
  end

  def update
    @ativo = Ativo.find params[:id]
    if @ativo.update(secure_params)
      redirect_to ativos_path, notice: "Ativo #{@ativo.nome_amigavel} atualizado com sucesso!"
    else
      render 'edit'
    end
  end

  private

  def secure_params
    params.require(:ativo).permit(:nome, :descricao, :moeda, :tipo, :cnpj)
  end

end