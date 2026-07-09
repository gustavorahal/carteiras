module PosicaoAtivoHelper

  def display_rentabilidade(posicao_ativo)
    html = [display_porcentagem(posicao_ativo.rentabilidade, cores: true)]
    if posicao_ativo.ativo.usd?
      html += [' | ', display_porcentagem(posicao_ativo.rentabilidade_em_brl, cores: true), ' ', content_tag(:small, 'em R$')]
    end

    safe_join(html)
  end

  def display_preco_atual(posicao_ativo)
    cotacao = posicao_ativo.cotacao
    ativo = posicao_ativo.ativo
    html = [display_moeda(cotacao.valor_unit, moeda: ativo.moeda_negociacao, max_precision: true)]
    html += [' ', content_tag(:small, "(#{display_data cotacao.data})")] unless cotacao.data == Date.today

    safe_join(html)
  end

  def display_preco_medio(posicao_ativo)
    ativo = posicao_ativo.ativo
    display_moeda posicao_ativo.preco_medio, moeda: ativo.moeda_negociacao
  end

  def display_valor_investido(posicao_ativo)
    ativo = posicao_ativo.ativo
    html = [display_moeda(posicao_ativo.valor_investido, moeda: ativo.moeda_negociacao)]
    if ativo.usd?
      html += [' | ', display_moeda(posicao_ativo.valor_investido_em_brl, moeda: 'BRL')]
    end
    safe_join(html)
  end
end
