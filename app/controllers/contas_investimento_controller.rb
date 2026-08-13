class ContasInvestimentoController < ApplicationController
  before_action :carregar_espaco
  before_action :carregar_ascendencia
  before_action :carregar_conta, only: %i[edit update arquivar restaurar]

  def new
    @conta = @carteira.contas_investimento.new
    authorize @conta
  end

  def create
    @conta = @carteira.contas_investimento.new(conta_params)
    authorize @conta
    ContaInvestimento.transaction do
      @conta.save!
      Array(params.dig(:conta_investimento, :moeda_ids)).reject(&:blank?).each do |id|
        @conta.contas_caixa.create!(moeda_id: id)
      end
    end
    redirect_to [@espaco, @investidor, @carteira], notice: "Conta criada."
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_content
  end

  def edit = authorize(@conta)

  def update
    authorize @conta
    @conta.update!(conta_params)
    redirect_to [@espaco, @investidor, @carteira], notice: "Conta atualizada."
  rescue ActiveRecord::RecordInvalid
    render :edit, status: :unprocessable_content
  end

  def arquivar
    authorize @conta, :arquivar?
    @conta.arquivar!
    redirect_to [@espaco, @investidor, @carteira]
  end

  def restaurar
    authorize @conta, :restaurar?
    @conta.restaurar!
    redirect_to [@espaco, @investidor, @carteira]
  end

  private

  def carregar_ascendencia
    @investidor = @espaco.investidores.find(params[:investidor_id])
    @carteira = @investidor.carteiras.find(params[:carteira_id])
  end
  def carregar_conta = @conta = @carteira.contas_investimento.find(params[:id])
  def conta_params = params.require(:conta_investimento).permit(:nome, :instituicao_id, :identificador_externo)
end
