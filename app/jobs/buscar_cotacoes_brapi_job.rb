class BuscarCotacoesBrapiJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(data = Date.current)
    Mercado.buscar_e_registrar_brapi(data:)
  end
end
