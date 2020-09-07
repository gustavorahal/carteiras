class ExtratosController < ApplicationController

  def import
    cc = ContaCorrente.find params[:conta_corrente_id]
    extrato_file = params[:file]
    if cc.corretora.nome == 'XP'
      begin
        ImportaExtrato.extrato_xp(cc, extrato_file.path)
        redirect_to conta_corrente_path(cc), notice: 'Extrato importado com sucesso'
      rescue TypeError => e
        redirect_to conta_corrente_path(cc), alert: e.message
      end
    else
      redirect_to conta_corrente_path(cc), alert: 'Corretora não suportada'
    end
  end

  def new
    @extrato = Extrato.new
    @conta_corrente = ContaCorrente.find params[:conta_corrente_id]
    @investidor = @conta_corrente.investidor
  end

  def create
    @extrato = Extrato.new secure_params
    @conta_corrente = ContaCorrente.find params[:conta_corrente_id]
    @investidor = @conta_corrente.investidor

    if @extrato.save
      redirect_to conta_corrente_path(@conta_corrente)
    else
      render 'new'
    end
  end

  private

  def secure_params
    params.require(:extrato).permit(:liquidacao, :movimentacao, :descricao, :valor, :file, :conta_corrente_id)
  end

end