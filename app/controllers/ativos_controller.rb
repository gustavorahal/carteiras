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


  private

  def secure_params
    params.require(:ativo).permit(:nome, :descricao, :moeda, :tipo)
  end

end