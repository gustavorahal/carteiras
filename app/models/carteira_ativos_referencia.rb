
# Posição da Carteira em relação a Referência que segue
class CarteiraAtivosReferencia
  def initialize(carteira_ativos)
    raise TypeError unless carteira_ativos.is_a? CarteiraAtivos

    @carteira_ativos = carteira_ativos
    @carteira = carteira_ativos.carteira
    @referencia = @carteira.referencia
    @ativos_posicoes = carteira_ativos.ativos_posicao
    @cotacao_usdbrl = CotacaoService.cotacao_usdbrl(Date.today)
  end

  def ativos_posicao_por_book
    lista = {}
    @ativos_posicoes.each do |cap|
      book = book_ativo(cap.ativo)
      lista[book] = [] unless book.in? lista
      lista[book].push cap
    end

    lista
  end

  def book_ativo(ativo)
    ref_ativo = @referencia.referencia_ativos.find_by(ativo: ativo)
    return if ref_ativo.nil?

    ref_ativo.book
  end

  def porcentagem_ref_ativo(ativo)
    referencia_ativo = @referencia.referencia_ativos.find_by(ativo: ativo)
    return if referencia_ativo.nil?

    referencia_ativo.porcentagem
  end

  def porcentagens_por_book
    lista = {}

    @ativos_posicoes.each do |ativo_posicao|
      book = book_ativo(ativo_posicao.ativo)
      lista[book] = 0 unless book.in? lista
      lista[book] += (ativo_posicao.valor_em_brl / @carteira_ativos.total_geral) * 100
    end

    lista
  end

  def valor_por_book
    lista = {}
    @ativos_posicoes.each do |cap|
      book = book_ativo(cap.ativo)
      lista[book] = 0 unless book.in? lista
      lista[book] += cap.valor_em_brl
    end

    lista
  end

  def valor_teorico(ativo)
    percent = porcentagem_ref_ativo(ativo)
    return 0 if percent.nil? || percent.zero?

    @carteira_ativos.total_geral * (percent / 100)
  end

  def diff_valor_referencia_brl(ativo)
    ativo_posicao = @carteira_ativos.busca_ativo_posicao(ativo)
    return valor_teorico(ativo) if ativo_posicao.nil?

    ativo_posicao.valor_em_brl - valor_teorico(ativo)
  end

  def diff_valor_referencia_usd(ativo)
    diff_valor_referencia_brl(ativo) / @cotacao_usdbrl.valor_unit
  end

end