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

    ativo_usdbrl = Ativo.find_by(nome: "USDBRL")
    @cotacao_usdbrl = CotacaoService.cotacao(ativo_usdbrl, @data) if ativo_usdbrl
  end
end
