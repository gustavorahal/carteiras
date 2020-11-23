class AdminService

  # Desdobramento de ação, ou seja, em quantas vezes ela foi reduzida
  #
  # @param n_vezes: dividir o valor da ação em quantas vezes?
  def self.desdobrar_acao(ativo, n_vezes)
    Operacao.where(ativo: ativo).each do |op|
      op.valor_unit = op.valor_unit / n_vezes
      op.quantidade = op.quantidade * n_vezes
      obs = "Desdobramento em #{n_vezes}x em #{Date.today}"
      op.observacao = op.observacao.nil? ? obs : op.observacao + '<br>' + obs
      op.save
    end
  end

end