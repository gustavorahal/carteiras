class ReferenciaAtivosController < ApplicationController

  def index
  end

  def new
    @referencia_ativo = ReferenciaAtivo.new
  end

  def create
    @referencia_ativo = ReferenciaAtivo.new
    if @referencia_ativo.save
      redirect_to referencias_path(@referencia_ativo.referencia),
                                                    notice: "Referência ativo #{@referencia_ativo.ativo.nome} adicionado com sucesso!"
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    if @referencia_ativo.update(secure_params)
      redirect_to referencias_path(@referencia_ativo),
                      notice: "Referencia ativo #{@referencia_ativo} atualizado com sucesso!"
    else
      render 'edit'
    end
  end


  private


  def secure_params
    params.require(:referencia_ativo).permit(:referencia_id, :ativo_id,
                                           :book, :porcentagem, :data_entrada, :data_saida)
  end

end