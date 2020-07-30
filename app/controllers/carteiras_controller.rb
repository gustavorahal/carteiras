class CarteirasController < ApplicationController

  def index
    @carteiras = Carteira.all
  end

  def show
    data_fim = Date.today.strftime '%F'
    @carteira = Carteira.find params[:id]
    carteira_posicao = @carteira.posicao(data_fim: data_fim)
    @carteira_completo = []
    @total_ativos_atual = 0

    carteira_posicao.each do |carteira_ativo_id, quantidade|
      carteira_ativo = CarteiraAtivo.includes(:ativo).find carteira_ativo_id
      data_mon = carteira_ativo.data_montagem
      preco_medio = Operacao.preco_medio(carteira_ativo_id, data_mon, data_fim)
      cotacao_atual = Cotacao.ultima_cotacao(carteira_ativo.ativo_id)
      if carteira_ativo.ativo.moeda == 'USD'
        preco_atual = cotacao_atual.valor_unit * Cotacao.ultima_cotacao_usdbrl.valor_unit
      else
        preco_atual = cotacao_atual.valor_unit
      end

      preco_atual_data = cotacao_atual.data
      valor_posicao = preco_atual * quantidade.to_f
      rentabilidade = ((preco_atual/preco_medio) - 1) * 100

      @total_ativos_atual += valor_posicao
      @carteira_completo.push [carteira_ativo, data_mon, valor_posicao, quantidade,
                               preco_medio, preco_atual, preco_atual_data, rentabilidade]
    end

    sum_total_c_e_v = CarteiraAtivo.joins(:operacoes).where(carteira_id: @carteira.id).sum('quantidade * valor_unit * usdbrl')
    @saldo_xp = Extrato.where(investidor_id: @carteira.investidor.id, moeda: 'BRL', corretora: 'XP').sum(:valor).round(2)
    extrato_avenue = Extrato.where(investidor_id: @carteira.investidor.id, corretora: 'Avenue')
    @cotacao_dolar = Cotacao.where(ativo_id: Ativo.find_by_nome('CURRENCY:USDBRL')).first.valor_unit
    @saldo_avenue_usd = extrato_avenue.where(moeda: 'USD').sum(:valor).round(2)
    @saldo_avenue_brl = extrato_avenue.where(moeda: 'BRL').sum(:valor).round(2)
    @saldo_corretoras = @saldo_xp + (@saldo_avenue_usd * @cotacao_dolar) + @saldo_avenue_brl
    @ultimas_operacoes = Operacao.operacoes_carteira(@carteira.id).limit(5)
    @total_geral = @total_ativos_atual + @saldo_corretoras
    @total_investido = sum_total_c_e_v + @saldo_corretoras
    @rentabilidade_carteira = (@total_geral / @total_investido - 1) * 100
    @books_porcentagem = {}
    @carteira_completo.each do |cc|
      carteira_ativo, valor_posicao = cc[0], cc[2]
      book = carteira_ativo.book
      @books_porcentagem[book] = 0 unless book.in? @books_porcentagem
      @books_porcentagem[book] += (valor_posicao / @total_geral) * 100
    end
  end

  def consolidado
    carteira = Carteira.find params[:id]
    @posicao_corretora_xp = carteira.posicao_corretora 'XP'
    @posicao_corretora_avenue = carteira.posicao_corretora 'Avenue'
  end


end