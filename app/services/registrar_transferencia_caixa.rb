class RegistrarTransferenciaCaixa
  def self.call(carteira:, usuario:, atributos:, **opcoes)
    RegistrarEventoFinanceiro.call(carteira:, usuario:, tipo: :transferencia_caixa, atributos:, **opcoes)
  end
end
