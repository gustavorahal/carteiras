module PosicaoHelper

  def valor_total_posicao_ativos(posicao_ativos)
    display_moeda posicao_ativos.inject(0) { |sum, pa| sum += pa.valor }, moeda: posicao_ativos[0].ativo.moeda_negociacao
  end

end