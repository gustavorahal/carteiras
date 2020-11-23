
# Posição da Carteira em relação a Referência que segue
class CarteiraAtivosReferencia
  def initialize(carteira_posicao)
    raise TypeError unless carteira_posicao.is_a? CarteiraAtivos

    @carteira_ativos = carteira_posicao # Objeto CarteiraPosicao
    @carteira = carteira_posicao.carteira
    @referencia = @carteira.referencia
    @ativos_posicoes = carteira_posicao.ativos_posicao
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
    return 0 if percent.nil? or percent.zero?

    @carteira_ativos.total_geral * (percent / 100)
  end

end