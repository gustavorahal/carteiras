class RegistrarEventoCorporativo
  def self.call(carteira:, usuario:, atributos:, **opcoes)
    RegistrarEventoFinanceiro.call(carteira:, usuario:, tipo: :evento_corporativo, atributos:, **opcoes)
  end
end
