class ApplicationController < ActionController::Base

  def index
    data_fim = '2020-07-13'
    invest = Investidor.find_by_nome 'Cláudio'

    # Quais ativos eu tenho na carteira até determinada data?
    #
    # Para isso somamos a quantidade que temos de cada ativo
    # e o que for diferente de zero significa que a temos na carteira.
    # Quantidade pode ser negativo. Exemplo: operação de short
    sql = <<~SQL
              SELECT ativos.nome, descricao, operacoes.ativo_id, 
                      carteira_ativos.book, 
                      ROUND(SUM(quantidade)::numeric, 10),
                      ativos.moeda, operacoes.usdbrl, descricao
              FROM operacoes
              INNER JOIN
                  ativos ON ativos.id = operacoes.ativo_id
              INNER JOIN
                  carteira_ativos ON ativos.id = carteira_ativos.ativo_id AND
                                     operacoes.investidor_id = carteira_ativos.investidor_id     
              WHERE operacoes.investidor_id = #{invest.id} AND
                    operacoes.data <= '#{data_fim}'
              GROUP BY ativos.nome, operacoes.ativo_id, carteira_ativos.book, ativos.moeda, operacoes.usdbrl, descricao
              HAVING ROUND(SUM(quantidade)::numeric, 10) <> 0
              ORDER BY carteira_ativos.book, ativos.nome ASC
          SQL

    carteira = ActiveRecord::Base.connection.execute(sql).values()
    @carteira_completo = []
    #@sum_total_investido = 0
    @total_ativos_atual = 0

    carteira.each do |ativo_nome, descricao, ativo_id, book, quantidade, moeda, usdbrl|
      # obtem data de montagem para calculo de preço médio posteriormente
      data_mon = Operacao.where(ativo_id: ativo_id,
                              investidor_id: invest.id,
                              mon_ou_des: 1).order(data: :desc).limit(1)[0].data

      # cálculo de preço médio
      sql = <<~SQL
              select sum(quantidade*valor_unit)/sum(quantidade) as preco_compra
              from operacoes
              where ativo_id = #{ativo_id} and
               investidor_id = #{invest.id} and
               operacao = 1 and 
               data >= '#{data_mon}' and  
               data <= '#{data_fim}'
            SQL

      preco_compra = ActiveRecord::Base.connection.execute(sql).values()[0][0]
      preco_compra = preco_compra * usdbrl if moeda == 'USD'
      cotacao_atual = Cotacao.where(ativo_id: ativo_id).order(data: :desc).limit(1)[0]
      preco_atual = cotacao_atual.valor_unit
      preco_atual = preco_atual * usdbrl if moeda == 'USD'
      preco_atual_data = cotacao_atual.data

      # @sum_total_investido += (preco_compra * quantidade.to_f) # serviria para que isso?
      valor_posicao = preco_atual * quantidade.to_f
      @total_ativos_atual += valor_posicao
      @carteira_completo.push [ativo_nome,ativo_id,descricao,book,
                               data_mon,valor_posicao,quantidade,preco_compra, preco_atual, preco_atual_data]
    end

    sum_total_c_e_v = Operacao.where(investidor_id: invest.id).sum("quantidade * valor_unit * usdbrl")
    @saldo_xp = Extrato.where(investidor_id: invest.id, moeda:'BRL', corretora:'XP').sum(:valor).round(2)
    extrato_avenue = Extrato.where(investidor_id: invest.id, corretora:'Avenue')
    @cotacao_dolar = Cotacao.where(ativo_id: Ativo.find_by_nome('CURRENCY:USDBRL')).first.valor_unit
    @saldo_avenue_usd = extrato_avenue.where(moeda: 'USD').sum(:valor).round(2)
    @saldo_avenue_brl = extrato_avenue.where(moeda: 'BRL').sum(:valor).round(2)
    @saldo_corretoras = @saldo_xp + (@saldo_avenue_usd * @cotacao_dolar) + @saldo_avenue_brl
    @ultimas_operacoes = Operacao.where(investidor_id: invest.id).order("data DESC").limit(5)
    @total_geral = @total_ativos_atual + @saldo_corretoras
    @total_investido = sum_total_c_e_v + @saldo_corretoras
    @rentabilidade_carteira = (@total_geral / @total_investido - 1) * 100

  end
end
