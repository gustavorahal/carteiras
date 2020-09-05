class ExtratosController < ApplicationController

  def index
    @moeda = params[:moeda]
    @extratos = Extrato
                .where(investidor_id: params[:investidor_id],
                       corretora_id: params[:corretora_id],
                       moeda: @moeda)
                .order(liquidacao: :desc)
    @saldo = @extratos.sum(:valor)
    @corretora = Corretora.find params[:corretora_id]
    @investidor = Investidor.find params[:investidor_id]
  end

  def import
    investidor = Investidor.find params[:investidor_id]
    corretora = Corretora.find params[:corretora_id]
    extrato_file = params[:file]
    if corretora.nome == 'XP'
      begin
        ImportaExtrato.extrato_xp(investidor.id, extrato_file.path)
        redirect_to extratos_path(investidor_id: investidor.id,
                                  corretora_id: corretora.id,
                                  moeda: 'BRL'),
                    notice: 'Extrato importado com sucesso'
      rescue TypeError => e
        redirect_to extratos_path(investidor_id: investidor.id,
                                  corretora_id: corretora.id,
                                  moeda: 'BRL'),
                    alert: e.message
      end
    else
      redirect_to extratos_path(investidor_id: investidor.id,
                                corretora_id: corretora.id),
                  alert: 'Corretora não suportada'
    end
  end

  def new
    @extrato = Extrato.new
    @corretora = Corretora.find params[:corretora_id]
    @investidor = Investidor.find params[:investidor_id]
  end

  def create
    @extrato = Extrato.new secure_params

    if @extrato.save
      redirect_to extratos_path investidor_id: @extrato.investidor_id,
                                corretora_id: @extrato.corretora_id
    else
      render 'new'
    end
  end

  private

  def secure_params
    params.require(:extrato).permit(:liquidacao,
                                    :movimentacao,
                                    :descricao, :valor, :moeda,
                                    :corretora, :investidor_id, :corretora_id,
                                    :file)
  end

end