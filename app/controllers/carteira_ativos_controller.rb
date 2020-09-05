class CarteiraAtivosController < ApplicationController

  before_action :set_vars, only: [:show, :edit, :update, :create, :new]
  before_action :set_carteira_ativo, only: [:show, :edit, :update, :create]

  def show
    @carteira_posicao = CarteiraPosicao.new(@carteira, Date.today)
  end

  def edit
  end

  def update
    if @carteira_ativo.update(secure_params)
      redirect_to carteira_carteira_ativo_path @carteira, @carteira_ativo, notice: "Carteira Ativo atualizada com sucesso!"
    else
      render 'edit'
    end
  end

  def new
    @carteira_ativo = CarteiraAtivo.new
  end

  def create
    @carteira_ativo = CarteiraAtivo.new secure_params
    @carteira_ativo.carteira = @carteira

    if @carteira_ativo.save
      redirect_to carteira_carteira_ativo_path @carteira, @carteira_ativo, notice: "Carteira Ativo criado com sucesso!"
    else
      render 'new'
    end

  end

  private

  def set_carteira_ativo
    @carteira_ativo = CarteiraAtivo.includes(:operacoes, :ativo).find(params[:id])
  end

  def set_vars
    @ativos = Ativo.all.order(:nome)
    @carteira = Carteira.find params[:carteira_id]
    @corretoras = Corretora.all.order(:nome)
  end

  def secure_params
    params.require(:carteira_ativo).permit(:carteira_id, :ativo_id,
                                           :book, :porcentagem, :valido, :corretora_id)
  end

end