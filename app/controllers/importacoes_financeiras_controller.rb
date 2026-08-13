class ImportacoesFinanceirasController < ApplicationController
  before_action :carregar_espaco
  before_action :carregar_importacao, only: %i[show criar_rascunhos]
  before_action :carregar_opcoes, only: %i[new create show criar_rascunhos]

  def index
    @importacoes = ImportacaoFinanceira.joins(:investidor).where(investidores: { espaco_id: @espaco.id })
      .includes(:investidor, :conta_investimento).order(created_at: :desc)
  end

  def new
  end

  def create
    conta = @contas.find(params.require(:conta_investimento_id))
    importacoes = ImportacoesFinanceiras.analisar(arquivos: params.require(:arquivos), conta:, usuario: current_user)
    if importacoes.one?
      redirect_to espaco_importacoes_financeira_path(@espaco, importacoes.first), notice: "Arquivo analisado."
    else
      redirect_to espaco_importacoes_financeiras_path(@espaco), notice: "#{importacoes.size} arquivos analisados."
    end
  rescue ActionController::ParameterMissing => erro
    redirect_to new_espaco_importacoes_financeira_path(@espaco), alert: erro.message
  end

  def show
    autorizar_leitura!
    preparar_conciliacao
  end

  def criar_rascunhos
    resolucoes = params[:resolucoes]&.to_unsafe_h || {}
    transacoes = ImportacoesFinanceiras.criar_rascunhos(importacao: @importacao, usuario: current_user, resolucoes:)
    redirect_to espaco_importacoes_financeira_path(@espaco, @importacao),
      notice: "#{transacoes.size} rascunho(s) criado(s); nada foi confirmado automaticamente."
  rescue Financeiro::AtributosInvalidos, Financeiro::EstadoInvalido => erro
    @importacao.reload
    preparar_conciliacao
    flash.now[:alert] = erro.detalhes.values.flatten.join(", ")
    render :show, status: :unprocessable_content
  end

  def confirmar_em_lote
    importacoes = ImportacaoFinanceira.joins(:investidor).where(investidores: { espaco_id: @espaco.id })
      .where(id: params.fetch(:importacao_ids, []))
    confirmadas = ImportacoesFinanceiras.confirmar_em_lote(importacoes:, usuario: current_user)
    redirect_to espaco_importacoes_financeiras_path(@espaco), notice: "#{confirmadas.size} transação(ões) confirmada(s) em ordem cronológica."
  rescue Financeiro::Erro => erro
    redirect_to espaco_importacoes_financeiras_path(@espaco), alert: erro.detalhes.values.flatten.join(", ")
  end

  private

  def carregar_importacao
    @importacao = ImportacaoFinanceira.joins(:investidor).where(investidores: { espaco_id: @espaco.id }).find(params[:id])
  end

  def carregar_opcoes
    @contas = ContaInvestimento.ativos.joins(carteira: :investidor)
      .where(investidores: { espaco_id: @espaco.id }).includes(:carteira, :instituicao).order(:nome)
    @ativos = Ativo.ativos.order(:codigo)
  end

  def autorizar_leitura!
    raise Financeiro::NaoAutorizado unless current_user.pode_ler?(@espaco)
  end

  def preparar_conciliacao
    @conciliacao = ImportacoesFinanceiras.conciliacao(importacao: @importacao, usuario: current_user)
    @itens_extrato = @conciliacao.itens_extrato
    @saldos_conciliados = @conciliacao.saldos
    @posicoes_conciliadas = @conciliacao.posicoes
  end
end
