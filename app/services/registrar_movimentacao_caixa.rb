class RegistrarMovimentacaoCaixa
  def self.call(carteira:, usuario:, atributos:, **opcoes)
    RegistrarEventoFinanceiro.call(carteira:, usuario:, tipo: :movimentacao_caixa, atributos:, **opcoes)
  end
end
