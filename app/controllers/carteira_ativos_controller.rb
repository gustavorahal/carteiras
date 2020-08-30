class CarteiraAtivosController < ApplicationController

  def show
    @carteira_ativo = CarteiraAtivo.includes(:operacoes, :ativo).find(params[:id])
  end

  def edit
    @carteira = Carteira.find params[:carteira_id]
    @carteira_ativo = CarteiraAtivo.find params[:id]
    @ativos = Ativo.all.order(:nome)
    @corretoras = Corretora.all.order(:nome)
  end

  def update
    @carteira_ativo = CarteiraAtivo.find params[:id]
    @carteira = Carteira.find params[:carteira_id]

    if @carteira_ativo.update(secure_params)
      redirect_to carteira_path @carteira, notice: "Carteira Ativo atualizada com sucesso!"
    else
      render 'edit'
    end
  end

  def new
    @carteira_ativo = CarteiraAtivo.new
    @carteira = Carteira.find params[:carteira_id]
    @ativos = Ativo.all.order(:nome)
    @corretoras = Corretora.all.order(:nome)
  end

  def create
    @carteira_ativo = CarteiraAtivo.new secure_params
    @ativos = Ativo.all.order(:nome)
    @corretoras = Corretora.all.order(:nome)
    @carteira = Carteira.find params[:carteira_id]
    @carteira_ativo.carteira = @carteira

    if @carteira_ativo.save
      redirect_to carteira_path @carteira
    else
      render 'new'
    end

  end

  private

  def secure_params
    params.require(:carteira_ativo).permit(:carteira_id, :ativo_id,
                                           :book, :porcentagem, :valido, :corretora_id)
  end

end