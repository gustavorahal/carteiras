class ContasCaixaController < ApplicationController
  before_action :carregar_espaco
  before_action :carregar_ascendencia

  def create
    caixa = @conta.contas_caixa.new(moeda_id: params.require(:conta_caixa)[:moeda_id])
    authorize caixa
    caixa.save!
    redirect_to [@espaco, @investidor, @carteira], notice: "Conta de caixa criada."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to [@espaco, @investidor, @carteira], alert: e.record.errors.full_messages.to_sentence
  end

  def arquivar
    caixa = @conta.contas_caixa.find(params[:id])
    authorize caixa, :arquivar?
    caixa.arquivar!
    redirect_to [@espaco, @investidor, @carteira], notice: "Conta de caixa arquivada."
  end

  def restaurar
    caixa = @conta.contas_caixa.find(params[:id])
    authorize caixa, :restaurar?
    caixa.restaurar!
    redirect_to [@espaco, @investidor, @carteira], notice: "Conta de caixa restaurada."
  end

  private

  def carregar_ascendencia
    @investidor = @espaco.investidores.find(params[:investidor_id])
    @carteira = @investidor.carteiras.find(params[:carteira_id])
    @conta = @carteira.contas_investimento.find(params[:conta_id])
  end
end
