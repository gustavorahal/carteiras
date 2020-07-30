class OperacoesController < ApplicationController

  def index
    @carteira = Carteira.find params[:carteira_id]
    @operacoes = Operacao.operacoes_carteira(params[:carteira_id])
  end

  def new
    @carteira = Carteira.find params[:carteira_id]
    @operacao = Operacao.new
    @carteira_ativos = CarteiraAtivo
                       .joins(:ativo)
                       .where(carteira_id: @carteira.id, valido: true)
                       .order(:descricao)
  end

  def create
    @operacao = Operacao.new secure_params

    if @operacao.save
      redirect_to carteira_operacoes_path carteira_id: params[:carteira_id]
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