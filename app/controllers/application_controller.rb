class ApplicationController < ActionController::Base
  before_action :set_data

  private

  def set_data
    @data = if params[:data].present?
              params[:data].to_date
            else
              Date.today
            end
  end
end
