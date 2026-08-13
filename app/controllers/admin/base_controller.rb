module Admin
  class BaseController < ApplicationController
    before_action :exigir_administrador_sistema

    private

    def exigir_administrador_sistema
      raise Financeiro::NaoAutorizado unless current_user.administrador_sistema?
    end
  end
end
