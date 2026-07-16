class VersoesReferenciaController < ApplicationController
  before_action :set_referencia

  def new
    @versao = @referencia.versoes.new
    authorize @versao
    @ativos = Ativo.ativos.order(:codigo)
  end

  def create
    @versao = @referencia.versoes.new(versao_params.except(:alocacoes))
    authorize @versao
    VersaoReferencia.transaction do
      @versao.save!
      alocacoes = versao_params[:alocacoes].to_h.values.reject { |a| a[:ativo_id].blank? }
      @versao.alocacoes.create!(alocacoes)
    end
    redirect_to referencia_versoes_referencia_path(@referencia, @versao), notice: "Versão criada."
  rescue ActiveRecord::RecordInvalid => e
    @versao = @referencia.versoes.new(versao_params.except(:alocacoes)) if @versao&.persisted?
    @ativos = Ativo.ativos.order(:codigo)
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
  end

  def show
    @versao = @referencia.versoes.find(params[:id])
    authorize @versao
    @alocacoes = @versao.alocacoes.includes(:ativo).to_a
  end

  def publicar
    @versao = @referencia.versoes.find(params[:id])
    authorize @versao, :publicar?
    PublicarVersaoReferencia.call(@versao)
    redirect_to referencia_versoes_referencia_path(@referencia, @versao), notice: "Versão publicada."
  rescue ArgumentError => e
    redirect_to referencia_versoes_referencia_path(@referencia, @versao), alert: e.message
  end

  private

  def set_referencia = @referencia = Referencia.find(params[:referencia_id])
  def versao_params = params.require(:versao_referencia).permit(:vigencia_inicial,
    alocacoes: %i[ativo_id categoria percentual])
end
