class ReferenciaAtivosController < ApplicationController

  before_action :set_vars, only: [:index, :new, :create, :edit, :update]

  def index
  end

  def new
    @ativos = @referencia.ativos_disponiveis
    @referencia_ativo = ReferenciaAtivo.new
  end

  def create
    @ativos = @referencia.ativos_disponiveis
    @referencia_ativo = ReferenciaAtivo.new secure_params

    if @referencia_ativo.porcentagem.zero?
      # se esta adicionando um novo ativo, não faz sentido deixar em zero
      flash.now[:alert] = "Porcentagem 0%?"
      render 'new'
    elsif @referencia_ativo.save
      redirect_to referencia_path(@referencia),
                  notice: "Referência ativo #{@referencia_ativo.ativo.nome} criado com sucesso!"
    else
      render 'new'
    end

  end

  def edit
    @referencia_ativo = ReferenciaAtivo.find params[:id]
  end

  def update
    @referencia_ativo = ReferenciaAtivo.find params[:id]
    if @referencia_ativo.update(secure_params)
      redirect_to referencia_path(@referencia),
                  notice: "Referencia ativo #{@referencia_ativo.ativo.nome} atualizado com sucesso!"
    else
      render 'edit'
    end
  end


  private


  def secure_params
    params.require(:referencia_ativo).permit(:referencia_id, :ativo_id,
                                             :book, :porcentagem, :data_entrada, :data_saida)
  end

  def set_vars
    @referencia = Referencia.find params[:referencia_id]
  end

end