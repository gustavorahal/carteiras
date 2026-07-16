class ExcluirEventoFinanceiroRascunho
  def self.call(evento)
    EventoFinanceiro.transaction do
      evento.lock!
      raise ArgumentError, "Somente rascunhos podem ser excluídos" unless evento.rascunho?
      evento.detalhe&.destroy!
      evento.destroy!
    end
  end
end
