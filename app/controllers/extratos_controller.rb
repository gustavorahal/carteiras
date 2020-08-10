class ExtratosController < ApplicationController

  def index
    @extratos = Extrato
                .where(investidor_id: params[:investidor_id],
                       corretora: params[:corretora])
                .order(liquidacao: :desc)
    @saldo = @extratos.sum(:valor)
    @corretora = params[:corretora]
    @investidor = Investidor.find params[:investidor_id]
  end

  def new
    @extrato = Extrato.new
    @corretora = params[:corretora]
    @investidor = Investidor.find params[:investidor_id]
  end

  def create
    @extrato = Extrato.new secure_params

    if @extrato.save
      redirect_to extrato_path @extrato, investidor_id: @extrato.investidor_id,
                               corretora: @extrato.corretora
    else
      render 'new'
    end

  end

  private

  def secure_params
    params.require(:extrato).permit(:liquidacao,
                                    :movimentacao,
                                    :descricao, :valor, :moeda,
                                    :corretora, :investidor_id)
  end

  end