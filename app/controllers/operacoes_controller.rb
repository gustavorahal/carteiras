class OperacoesController < ApplicationController

  def index
    @operacoes = Operacao.operacoes_carteira(params[:carteira_id])
  end

  def new
    @operacao = Operacao.new
    @carteira_ativos = CarteiraAtivo
                       .joins(:ativo)
                       .where(carteira_id: params[:carteira_id], valido: true)
                       .order(:descricao)
  end

  def create
    @operacao = Operacao.new secure_params

    if @operacao.save
      redirect_to operacoes_path carteira_id: params[:carteira_id]
    else
      render 'new'
    end
  end

  private

  def secure_params
    params.require(:operacao).permit(:carteira_ativo_id, :mon_ou_des,
                                     :data, :valor_unit, :quantidade, :corretora,
                                     :operacao)
  end

end