class ContasInvestimentoController < ApplicationController
  before_action :set_carteira
  before_action :set_conta, only: %i[show edit update]
  before_action :carregar_formulario, only: %i[new create edit update]

  def index = @contas = policy_scope(@carteira.contas_investimento).includes(:corretora, contas_caixa: :moeda)
  def show = authorize(@conta)

  def new
    @conta = @carteira.contas_investimento.new
    authorize @conta
  end

  def create
    @conta = @carteira.contas_investimento.new(conta_params)
    authorize @conta
    ContaInvestimento.transaction do
      @conta.save!
      adicionar_contas_caixa
    end
    redirect_to carteira_contas_investimento_index_path(@carteira), notice: "Conta criada."
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  def edit = authorize(@conta)

  def update
    authorize @conta
    ContaInvestimento.transaction do
      @conta.update!(conta_params)
      adicionar_contas_caixa
    end
    redirect_to carteira_contas_investimento_index_path(@carteira), notice: "Conta atualizada."
  rescue ActiveRecord::RecordInvalid
    render :edit, status: :unprocessable_entity
  end

  private

  def set_carteira = @carteira = policy_scope(Carteira).find(params[:carteira_id])
  def set_conta = @conta = policy_scope(@carteira.contas_investimento).includes(:contas_caixa).find(params[:id])
  def conta_params = params.require(:conta_investimento).permit(:corretora_id, :nome, :identificador_externo, :arquivado_em)

  def carregar_formulario
    @corretoras = Corretora.ativas.order(:nome)
    @moedas = Moeda.ativas.order(:codigo)
  end

  def adicionar_contas_caixa
    ids = params.dig(:conta_investimento, :moeda_ids).to_a.compact_blank
    moedas = ids.present? ? @moedas.where(id: ids) : [@carteira.moeda_base]
    moedas.each { |moeda| @conta.contas_caixa.find_or_create_by!(moeda:) }
  end
end
