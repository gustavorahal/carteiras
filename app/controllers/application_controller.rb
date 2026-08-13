class ApplicationController < ActionController::Base
  include Pundit::Authorization
  before_action :authenticate_user!
  before_action :set_data

  rescue_from Financeiro::NaoAutorizado, with: ->(erro) { render_erro_financeiro(erro, :forbidden) }
  rescue_from Financeiro::EscopoInvalido, with: ->(erro) { render_erro_financeiro(erro, :not_found) }
  rescue_from Financeiro::EstadoInvalido, Financeiro::ConflitoIdempotencia,
    with: ->(erro) { render_erro_financeiro(erro, :conflict) }
  rescue_from Financeiro::AtributosInvalidos, Financeiro::HistoricoInvalido, Financeiro::RegistroArquivado,
    with: ->(erro) { render_erro_financeiro(erro, :unprocessable_content) }
  rescue_from Pundit::NotAuthorizedError, with: -> { head :forbidden }
  rescue_from ActiveRecord::RecordNotFound, with: -> { head :not_found }

  private

  def set_data
    @data = params[:data].present? ? Date.parse(params[:data].to_s) : Date.current
  rescue Date::Error
    @data = Date.current
  end


  def carregar_espaco
    @espaco = policy_scope(Espaco).find(params[:espaco_id])
  end

  def render_erro_financeiro(erro, status)
    respond_to do |format|
      format.html do
        flash.now[:alert] = erro.detalhes.values.flatten.join(", ").presence || erro.message
        render plain: flash.now[:alert], status:
      end
      format.json { render json: { codigo: erro.codigo, detalhes: erro.detalhes }, status: }
    end
  end
end
