class ConsultarPosicaoHistorica
  def self.call(carteira:, data:)
    ReconstruirPosicoesCarteira.call(carteira:, ate: data, persistir: false)
  end
end
