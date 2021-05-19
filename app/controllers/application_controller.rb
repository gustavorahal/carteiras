class ApplicationController < ActionController::Base
  include Pundit
  before_action :authenticate_user!
  before_action :set_data

  private

  def set_data
    @data = if params[:data].present?
              params[:data].to_date
            else
              Date.today
            end
    @cotacao_usdbrl = CotacaoService.moedas('USDBRL', @data)
  end
end
