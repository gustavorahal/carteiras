module PosicaoAtivoHelper

  def display_rentabilidade(posicao_ativo)
    html_str = display_porcentagem posicao_ativo.rentabilidade, cores: true
    if posicao_ativo.ativo.usd?
      html_str += " | #{display_porcentagem(posicao_ativo.rentabilidade_em_brl, cores: true)} <small>em R$</small>".html_safe
    end

    html_str.html_safe
  end

  def display_preco_atual(posicao_ativo)
    cotacao = posicao_ativo.cotacao
    ativo = posicao_ativo.ativo
    html_str = display_moeda cotacao.valor_unit, moeda: ativo.moeda_negociacao
    html_str += " <small>(#{display_data cotacao.data})</small>".html_safe unless cotacao.data == Date.today

    html_str
  end

  def display_preco_medio(posicao_ativo)
    ativo = posicao_ativo.ativo
    display_moeda posicao_ativo.preco_medio, moeda: ativo.moeda_negociacao
  end

  def display_valor_investido(posicao_ativo)
    ativo = posicao_ativo.ativo
    html_str = display_moeda posicao_ativo.valor_investido, moeda: ativo.moeda_negociacao
    if ativo.usd?
      html_str += " | #{display_moeda(posicao_ativo.valor_investido_em_brl, moeda: 'BRL')}".html_safe
    end
    html_str.html_safe
  end
end
