module AtivoPosicaoHelper

  def display_rentabilidade(ativo_posicao)
    html_str = display_porcentagem ativo_posicao.rentabilidade, cores: true
    if ativo_posicao.ativo.usd?
      html_str += " | #{display_porcentagem(ativo_posicao.rentabilidade_em_brl, cores: true)} <small>em R$</small>".html_safe
    end

    html_str.html_safe
  end

  def display_preco_atual(ativo_posicao)
    cotacao = ativo_posicao.cotacao
    ativo = ativo_posicao.ativo
    html_str = display_moeda cotacao.valor_unit, moeda: ativo.moeda
    html_str += " <small>(#{display_data cotacao.data})</small>".html_safe unless cotacao.data == Date.today

    html_str
  end

  def display_preco_medio(ativo_posicao)
    ativo = ativo_posicao.ativo
    display_moeda ativo_posicao.preco_medio, moeda: ativo.moeda
  end

  def display_valor_investido(ativo_posicao)
    ativo = ativo_posicao.ativo
    html_str = display_moeda ativo_posicao.valor_investido, moeda: ativo.moeda
    if ativo.usd?
      html_str += " | #{display_moeda(ativo_posicao.valor_investido_em_brl, moeda: 'BRL')}".html_safe
    end
    html_str.html_safe
  end
end
