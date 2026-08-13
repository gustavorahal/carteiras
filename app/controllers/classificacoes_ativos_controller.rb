class ClassificacoesAtivosController < ApplicationController
  before_action :carregar_espaco
  before_action :carregar_investidor
  before_action :carregar_carteira

  def create
    authorize @carteira, :update?
    ativo = Ativo.find(classificacao_params[:ativo_id])
    classificacao = @carteira.classificacoes_ativos.find_or_initialize_by(ativo:)

    if classificacao_params[:categoria].blank?
      classificacao.destroy! if classificacao.persisted?
      mensagem = "Ativo marcado como não classificado."
    else
      classificacao.update!(categoria: classificacao_params[:categoria])
      mensagem = "Categoria de alocação atualizada."
    end

    redirect_to painel_path, notice: mensagem
  rescue ActiveRecord::RecordInvalid => erro
    redirect_to painel_path, alert: erro.record.errors.full_messages.to_sentence
  end

  private

  def carregar_investidor = @investidor = @espaco.investidores.find(params[:investidor_id])
  def carregar_carteira = @carteira = @investidor.carteiras.find(params[:carteira_id])
  def classificacao_params = params.require(:classificacao_ativo).permit(:ativo_id, :categoria)

  def painel_path
    espaco_investidor_carteira_path(@espaco, @investidor, @carteira,
      data: params[:data], inicio: params[:inicio], fim: params[:fim], anchor: "posicoes")
  end
end
