class ApplicationController < ActionController::Base

  def index
    data_fim = Date.today.strftime '%F'
    @carteira = Carteira.find params[:carteira_id]
    carteira_posicao = @carteira.posicao(data_fim)
    @carteira_completo = []
    @total_ativos_atual = 0

    carteira_posicao.each do |ativo_id, ativo_nome, descricao, book, quantidade, usdbrl, carteira_ativo_id|
      data_mon = Operacao.data_montagem(carteira_ativo_id)
      preco_medio = Operacao.preco_medio(carteira_ativo_id, data_mon, data_fim)
      cotacao_atual = Cotacao.ultima_cotacao(ativo_id)
      preco_atual = cotacao_atual.valor_unit * usdbrl
      preco_atual_data = cotacao_atual.data

      # @sum_total_investido += (preco_compra * quantidade.to_f) # serviria para que isso?
      valor_posicao = preco_atual * quantidade.to_f
      rentabilidade = ((preco_atual/preco_medio) - 1) * 100

      @total_ativos_atual += valor_posicao
      @carteira_completo.push [ativo_nome, ativo_id, descricao, book,
                               data_mon, valor_posicao, quantidade, preco_medio,
                               preco_atual, preco_atual_data, rentabilidade]
    end

    sum_total_c_e_v = CarteiraAtivo.joins(:operacoes).where(carteira_id: @carteira.id).sum('quantidade * valor_unit * usdbrl')
    @saldo_xp = Extrato.where(investidor_id: @carteira.investidor.id, moeda: 'BRL', corretora: 'XP').sum(:valor).round(2)
    extrato_avenue = Extrato.where(investidor_id: @carteira.investidor.id, corretora: 'Avenue')
    @cotacao_dolar = Cotacao.where(ativo_id: Ativo.find_by_nome('CURRENCY:USDBRL')).first.valor_unit
    @saldo_avenue_usd = extrato_avenue.where(moeda: 'USD').sum(:valor).round(2)
    @saldo_avenue_brl = extrato_avenue.where(moeda: 'BRL').sum(:valor).round(2)
    @saldo_corretoras = @saldo_xp + (@saldo_avenue_usd * @cotacao_dolar) + @saldo_avenue_brl
    @ultimas_operacoes = Operacao.joins(carteira_ativo: :ativo).where(carteira_id: @carteira.id).order('data DESC').limit(5)
    @total_geral = @total_ativos_atual + @saldo_corretoras
    @total_investido = sum_total_c_e_v + @saldo_corretoras
    @rentabilidade_carteira = (@total_geral / @total_investido - 1) * 100
    @books_porcentagem = {}
    @carteira_completo.each do |cc|
      book, valor_posicao = cc[3], cc[5]
      @books_porcentagem[book] = 0 unless book.in? @books_porcentagem
      @books_porcentagem[book] += (valor_posicao / @total_geral) * 100
    end



  end
end
