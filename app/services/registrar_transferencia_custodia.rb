class RegistrarTransferenciaCustodia
  def self.call(carteira:, usuario:, atributos:, **opcoes)
    RegistrarEventoFinanceiro.call(carteira:, usuario:, tipo: :transferencia_custodia, atributos:, **opcoes)
  end
end
