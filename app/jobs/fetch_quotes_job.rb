class FetchQuotesJob < ApplicationJob
  queue_as :default

  def perform(data = Date.current)
    CotacaoService.busca_e_registra_tudo(data)
  end
end
