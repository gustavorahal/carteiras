class ImportacoesExtratoController < ApplicationController
  before_action :set_carteira

  def new
    authorize @carteira, :update?
    @contas_caixa = @carteira.contas_caixa.includes(:moeda, :conta_investimento).to_a
  end

  def create
    authorize @carteira, :update?
    conta = @carteira.contas_caixa.find(params[:conta_caixa_id])
    @importacao = NormalizarImportacaoExtrato.call(conta_caixa: conta, arquivo: params.require(:arquivo),
      formato: params.require(:formato))
    redirect_to carteira_importacoes_extrato_path(@carteira, @importacao), notice: "Arquivo normalizado."
  rescue ActiveRecord::RecordInvalid, ArgumentError => e
    redirect_to new_carteira_importacoes_extrato_path(@carteira), alert: e.message
  end

  def show
    carregar_importacao
    authorize @importacao
    @itens = @importacao.itens.order(:ordem)
    datas = @itens.map(&:data_liquidacao)
    @lancamentos = if datas.empty?
      []
    else
      LancamentoCaixa.where(conta_caixa: @importacao.conta_caixa,
        data_efetiva: (datas.min - 3.days)..(datas.max + 3.days)).order(:data_efetiva).to_a
    end
  end

  def processar
    carregar_importacao
    authorize @importacao, :update?
    ProcessarItensImportacaoJob.perform_later(@importacao, current_user)
    redirect_to carteira_importacoes_extrato_path(@carteira, @importacao), notice: "Processamento agendado."
  end

  def resolver_item
    carregar_importacao
    authorize @importacao, :update?
    item = @importacao.itens.find(params.require(:item_id))
    lancamento = params[:lancamento_caixa_id].present? ? LancamentoCaixa.find(params[:lancamento_caixa_id]) : nil
    ConciliarItemExtrato.resolver(item:, usuario: current_user, decisao: params.require(:decisao),
      lancamento:, classificacao: params[:classificacao])
    redirect_to carteira_importacoes_extrato_path(@carteira, @importacao), notice: "Item resolvido."
  rescue ActiveRecord::RecordInvalid, ArgumentError => e
    redirect_to carteira_importacoes_extrato_path(@carteira, @importacao), alert: e.message
  end

  private

  def set_carteira = @carteira = policy_scope(Carteira).find(params[:carteira_id])

  def carregar_importacao
    @importacao = ImportacaoExtrato.joins(conta_caixa: :conta_investimento)
      .where(contas_investimento: { carteira_id: @carteira.id }).find(params[:id])
  end
end
