class BuscarCotacoesFechamentoJob < ApplicationJob
  queue_as :default

  def perform(data: Date.current)
    buscadores = BuscadoresCotacao.configurados
    Rails.logger.warn("Nenhum buscador de cotação foi configurado") if buscadores.empty?
    Ativo.ativos.find_each do |ativo|
      SelecionarCotacao.ativo(ativo:, data:, buscadores:)
    rescue StandardError => e
      Rails.logger.warn("Cotação de #{ativo.codigo} não atualizada: #{e.message}")
    end
  end
end
