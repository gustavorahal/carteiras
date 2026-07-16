class ConsultarPosicaoAtivo
  Resultado = Data.define(:posicao, :cotacao, :eventos)

  def self.call(carteira:, ativo:, data: Date.current)
    posicao = ConsultarPosicaoCarteira.call(carteira:, data:).itens.find { |item| item.posicao.ativo_id == ativo.id }
    eventos = carteira.eventos_financeiros.confirmado
      .left_joins(:operacao, :transferencia_custodia, :evento_corporativo)
      .includes(:operacao, :transferencia_custodia, :evento_corporativo)
      .where("operacoes.ativo_id = :id OR transferencias_custodia.ativo_id = :id OR eventos_corporativos.ativo_origem_id = :id OR eventos_corporativos.ativo_destino_id = :id", id: ativo.id)
      .distinct.ordenados_para_replay
    Resultado.new(posicao: posicao&.posicao, cotacao: posicao&.cotacao, eventos: eventos.to_a)
  end
end
