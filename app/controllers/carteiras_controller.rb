class CarteirasController < ApplicationController
  before_action :carregar_espaco
  before_action :carregar_investidor
  before_action :carregar_carteira, only: %i[show edit update arquivar restaurar]

  def show
    authorize @carteira
    @inicio = params[:inicio].present? ? Date.iso8601(params[:inicio]) : @data - 30
    @fim = params[:fim].present? ? Date.iso8601(params[:fim]) : @data
    @posicao = if @data == Date.current
      ConsultasFinanceiras.posicao_atual(carteira: @carteira, usuario: current_user)
    else
      ConsultasFinanceiras.posicao_historica(carteira: @carteira, data: @data, usuario: current_user)
    end
    @saldos = ConsultasFinanceiras.saldos_caixa(carteira: @carteira, data: @data, usuario: current_user)
    @totais_por_corretora = ConsultasFinanceiras.totais_por_corretora(posicao: @posicao, saldos: @saldos)
    @totais_por_categoria = ConsultasFinanceiras.totais_por_categoria(posicao: @posicao)
    itens_por_categoria = @posicao.itens.group_by { |item| item[:categoria].presence || "nao_classificado" }
    @posicoes_por_categoria = @totais_por_categoria.itens.map do |resumo|
      { resumo:, itens: itens_por_categoria.fetch(resumo[:categoria]).sort_by { |item| [item[:ativo], item[:instituicao]] } }
    end
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
