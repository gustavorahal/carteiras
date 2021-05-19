
# Posição da Carteira em relação a Referência que segue
class PosicaoReferencia
  def initialize(posicao)
    raise TypeError unless posicao.is_a? Posicao

    @posicao = posicao
    @carteira = posicao.carteira
    @referencia = @carteira.referencia
    @posicao_ativos = posicao.posicao_ativos
    @cotacao_usdbrl = CotacaoService.moedas('USDBRL', Date.today)
  end

  def ativos_posicao_por_book
    lista = {}
    @posicao_ativos.each do |cap|
      book = _book_ativo(cap.ativo)
      lista[book] = [] unless book.in? lista
      lista[book].push cap
    end

    lista
  end

  def porcentagens_por_book
    lista = {}

    @posicao_ativos.each do |posicao_ativo|
      book = _book_ativo(posicao_ativo.ativo)
      lista[book] = 0 unless book.in? lista
      lista[book] += (posicao_ativo.valor_em_brl / @posicao.total_geral) * 100
    end

    lista
  end

  def valor_por_book
    lista = {}
    @posicao_ativos.each do |cap|
      book = _book_ativo(cap.ativo)
      lista[book] = 0 unless book.in? lista
      lista[book] += cap.valor_em_brl
    end

    lista
  end

  def diff_valor_referencia_brl(ativo)
    posicao_ativo = @posicao.busca_posicao_ativo(ativo)
    return _valor_teorico(ativo) if posicao_ativo.nil?

    posicao_ativo.valor_em_brl - _valor_teorico(ativo)
  end

  def diff_valor_referencia_usd(ativo)
    diff_valor_referencia_brl(ativo) / @cotacao_usdbrl.valor_unit
  end

  def diff_quant_referencia(ativo)
    ultima_cotacao = CotacaoService.cotacao(ativo, Date.today)
    if ativo.usd?
      diff_valor_referencia_usd(ativo) / ultima_cotacao.valor_unit
    else
      diff_valor_referencia_brl(ativo) / ultima_cotacao.valor_unit
    end
  end

  #
  # Private
  #

  def _book_ativo(ativo)
    ref_ativo = @referencia.referencia_ativos.find_by(ativo: ativo)
    return if ref_ativo.nil?

    ref_ativo.book
  end

  def _valor_teorico(ativo)
    percent = _porcentagem_ref_ativo(ativo)
    return 0 if percent.nil? || percent.zero?

    @posicao.total_geral * (percent / 100)
  end

  def _porcentagem_ref_ativo(ativo)
    referencia_ativo = @referencia.referencia_ativos.find_by(ativo: ativo)
    return if referencia_ativo.nil?

    referencia_ativo.porcentagem
  end

end