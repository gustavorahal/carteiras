class ApplicationController < ActionController::Base
  include Pundit::Authorization
  before_action :authenticate_user!
  before_action :set_data

  private

  def set_data
    @data = if params[:data].present?
              params[:data].to_date
            else
              Date.today
            end
    return unless user_signed_in?

    @cotacao_usdbrl = CotacaoService.moedas("USDBRL", @data)
  rescue StandardError => e
    Rails.logger.warn "Não foi possível carregar cotação USDBRL para o menu: #{e.message}"
    @cotacao_usdbrl = nil
  end
end
