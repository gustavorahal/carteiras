class ReverterEventoFinanceiro
  def self.call(evento:, usuario:, chave_idempotencia: nil, observacao: nil)
    return evento.reversao if evento.revertido?

    EventoFinanceiro.transaction do
      evento.carteira.lock!
      evento.reload
      return evento.reversao if evento.revertido?
      reversao = EventoFinanceiro.create!(carteira: evento.carteira, usuario_responsavel: usuario,
        tipo: :reversao, origem: :manual, estado: :rascunho, data_competencia: evento.data_competencia,
        evento_revertido: evento, chave_idempotencia:, observacao:)
      ConfirmarEventoFinanceiro.call(reversao)
    end
  rescue ActiveRecord::RecordNotUnique => erro
    reversao = evento.reload.reversao
    raise erro unless reversao
    reversao.confirmado? ? reversao : ConfirmarEventoFinanceiro.call(reversao)
  end
end
