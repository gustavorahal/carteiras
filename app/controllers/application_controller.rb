class ApplicationController < ActionController::Base
  include Pundit::Authorization
  before_action :authenticate_user!
  before_action :set_data

  private

  def set_data
    @data = params[:data].present? ? Date.parse(params[:data].to_s) : Date.current
  rescue Date::Error
    @data = Date.current
  end
end
