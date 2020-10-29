module CarteiraPosicoesHelper

  def display_rentabilidade(carteira_ativo_posicao)
    html_str = display_porcentagem carteira_ativo_posicao.rentabilidade, cores: true
    if carteira_ativo_posicao.ativo.moeda == 'USD'
      html_str += " | #{display_porcentagem(carteira_ativo_posicao.rentabilidade_em_brl, cores: true)} <small>em R$</small>".html_safe
    end

    html_str.html_safe
  end

  def display_preco_atual(carteira_ativo_posicao)
    cotacao = carteira_ativo_posicao.cotacao
    ativo = carteira_ativo_posicao.ativo
    html_str = display_moeda cotacao.valor_unit, moeda: ativo.moeda
    html_str += "<small>(#{display_data cotacao.data})</small>".html_safe unless cotacao.data == Date.today

    html_str
  end

end
