class ExtratosController < ApplicationController

  def index
    @extratos = Extrato
                .where(investidor_id: params[:investidor_id],
                       corretora: params[:corretora])
                .order(liquidacao: :desc)
    @saldo = @extratos.sum(:valor)
    @corretora = params[:corretora]
  end

end