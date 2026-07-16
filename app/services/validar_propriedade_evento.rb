class ValidarPropriedadeEvento
  def self.call(evento)
    detalhe = evento.detalhe
    contas = case detalhe
    when Operacao, Provento, EventoCorporativo then [detalhe.conta_investimento]
    when MovimentacaoCaixa then [detalhe.conta_caixa.conta_investimento]
    when TransferenciaCaixa then [detalhe.conta_caixa_origem.conta_investimento, detalhe.conta_caixa_destino.conta_investimento]
    when TransferenciaCustodia then [detalhe.conta_origem, detalhe.conta_destino]
    else []
    end
    return evento if contas.all? { |conta| conta.carteira_id == evento.carteira_id }

    evento.errors.add(:base, "Todas as contas devem pertencer à carteira do evento")
    raise ActiveRecord::RecordInvalid, evento
  end
end
