class RegistrarProvento
  def self.call(carteira:, usuario:, atributos:, **opcoes)
    RegistrarEventoFinanceiro.call(carteira:, usuario:, tipo: :provento, atributos:, **opcoes)
  end
end
