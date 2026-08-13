class BuscarCotacoesYahooJob < ApplicationJob
  queue_as :default
  retry_on StandardError, attempts: 3

  def perform(data = Date.current)
    Mercado.buscar_e_registrar_yahoo(data:)
  end
end
