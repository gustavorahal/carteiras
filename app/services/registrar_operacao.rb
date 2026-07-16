class RegistrarOperacao
  def self.call(carteira:, usuario:, atributos:, **opcoes)
    RegistrarEventoFinanceiro.call(carteira:, usuario:, tipo: :operacao, atributos:, **opcoes)
  end
end
