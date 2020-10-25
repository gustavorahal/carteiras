class ApplicationController < ActionController::Base
  before_action :set_data

  private

  def set_data
    @data = if params[:data].present?
              params[:data].to_date
            else
              Date.today
            end
    @cotacao_usdbrl = CotacaoService.cotacao_usdbrl(@data)
  end
end
