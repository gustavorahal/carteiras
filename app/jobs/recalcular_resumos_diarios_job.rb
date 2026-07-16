class RecalcularResumosDiariosJob < ApplicationJob
  queue_as :default

  def perform(carteira, inicio, fim = Date.current)
    RecalcularResumosDiarios.call(carteira:, inicio:, fim:)
  end
end
