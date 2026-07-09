class ReferenciaAtivosController < ApplicationController

  before_action :set_vars, only: [:index, :new, :create, :edit, :update]

  def index
    @referencia_ativos = policy_scope(@referencia.referencia_ativos)
  end

  def new
    @ativos = policy_scope(Ativo).order(:nome) - @referencia.ativos.where.not('referencia_ativos.porcentagem': 0)
    @referencia_ativo = ReferenciaAtivo.new
    authorize @referencia_ativo
  end

  def create
    @ativos = policy_scope(Ativo).order(:nome) - @referencia.ativos.where.not('referencia_ativos.porcentagem': 0)
    @referencia_ativo = @referencia.referencia_ativos.new secure_params.except(:referencia_id)
    authorize @referencia_ativo

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
    @referencia_ativo = policy_scope(@referencia.referencia_ativos).find params[:id]
    authorize @referencia_ativo
  end

  def update
    @referencia_ativo = policy_scope(@referencia.referencia_ativos).find params[:id]
    authorize @referencia_ativo

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
    @referencia = policy_scope(Referencia).find params[:referencia_id]
  end

end
