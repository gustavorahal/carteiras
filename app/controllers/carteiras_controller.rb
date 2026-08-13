class CarteirasController < ApplicationController
  before_action :carregar_espaco
  before_action :carregar_investidor
  before_action :carregar_carteira, only: %i[show edit update arquivar restaurar]

  def show
    authorize @carteira
    @inicio = params[:inicio].present? ? Date.iso8601(params[:inicio]) : @data - 30
    @fim = params[:fim].present? ? Date.iso8601(params[:fim]) : @data
    @composicao = ConsultasFinanceiras.composicao(carteira: @carteira, data: @data, usuario: current_user)
    @posicao = @composicao.posicao
    @saldos = @composicao.saldos
    @patrimonio_total = @composicao.patrimonio_total_base
    @totais_por_corretora = @composicao.totais_por_corretora
    @totais_por_categoria = @composicao.totais_por_categoria
    @posicoes_por_categoria = @composicao.grupos_posicoes
    @variacoes_cotacao = ConsultasFinanceiras.variacoes_cotacao(carteira: @carteira, inicio: @inicio, fim: @fim,
      ativo_ids: @posicao.itens.pluck(:ativo_id), usuario: current_user).itens.index_by { |item| item[:ativo_id] }
    @resultados = ConsultasFinanceiras.resultados_realizados(carteira: @carteira, inicio: @inicio, fim: @fim, usuario: current_user)
    @rentabilidade = ConsultasFinanceiras.rentabilidade(carteira: @carteira, inicio: @inicio, fim: @fim, usuario: current_user)
  rescue Date::Error
    raise Financeiro::AtributosInvalidos.new(periodo: ["datas inválidas"])
  end

  def new
    @carteira = @investidor.carteiras.new
    authorize @carteira
  end

  def create
    @carteira = @investidor.carteiras.new(carteira_params)
    authorize @carteira
    @carteira.save!
    redirect_to [@espaco, @investidor, @carteira], notice: "Carteira criada."
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_content
  end

  def edit = authorize(@carteira)

  def update
    authorize @carteira
    @carteira.update!(carteira_params)
    redirect_to [@espaco, @investidor, @carteira], notice: "Carteira atualizada."
  rescue ActiveRecord::RecordInvalid
    render :edit, status: :unprocessable_content
  end

  def arquivar
    authorize @carteira, :arquivar?
    @carteira.arquivar!
    redirect_to @espaco
  end

  def restaurar
    authorize @carteira, :restaurar?
    @carteira.restaurar!
    redirect_to [@espaco, @investidor, @carteira]
  end

  private

  def carregar_investidor = @investidor = @espaco.investidores.find(params[:investidor_id])
  def carregar_carteira = @carteira = @investidor.carteiras.find(params[:id])
  def carteira_params = params.require(:carteira).permit(:nome, :moeda_base_id)
end
