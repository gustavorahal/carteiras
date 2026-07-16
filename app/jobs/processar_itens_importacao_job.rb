class ProcessarItensImportacaoJob < ApplicationJob
  queue_as :default

  def perform(importacao, usuario)
    importacao.update!(estado: :processando, erro_resumido: nil)
    importacao.itens.where(estado_conciliacao: %w[pendente ambiguo]).find_each do |item|
      ConciliarItemExtrato.call(item:, usuario:)
    end
    importacao.update!(estado: :concluida,
      itens_processados: importacao.itens.where.not(estado_conciliacao: :pendente).count,
      itens_pendentes: importacao.itens.where(estado_conciliacao: %w[pendente ambiguo]).count)
  rescue StandardError => e
    importacao.update!(estado: :falhou, erro_resumido: e.message.truncate(1_000))
    raise
  end
end
