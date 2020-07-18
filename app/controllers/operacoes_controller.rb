class OperacoesController < ApplicationController

  def index
    @operacoes = Operacao.joins(carteira_ativo: :ativo).where(carteira_id: params[:carteira_id]).order(created_at: :desc)
  end

  def new
    @operacao = Operacao.new
  end

  def create
    @operacao = Operacao.new secure_params
    @operacao.carteira_id = 1

    if @operacao.save
      redirect_to operacoes_path
    else
      render 'new'
    end
  end

  private

  def secure_params
    params.require(:operacao).permit(:ativo_id, :investidor_id, :mon_ou_des,
                                     :data, :valor_unit, :quantidade, :corretora, :operacao)
  end

end