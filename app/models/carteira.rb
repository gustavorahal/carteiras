class Carteira < ApplicationRecord
  has_many :carteira_ativos
  belongs_to :investidor

  # Quais ativos eu tenho na carteira até determinada data?
  #
  # Retorna um array de ativos da carteira com as seguintes informações:
  # ativo_id, nome, descrição, book, quantidade, cotacao USDBRL e carteira_ativo_id
  def posicao(data_fim: Date.today.strftime('%F'))
    # Para isso somamos a quantidade que temos de cada ativo
    # e o que for diferente de zero significa que temos o ativo na carteira.
    # Quantidade pode ser negativo. Exemplo: operação de short
    sql = <<~SQL
      SELECT carteira_ativos.id, ROUND(SUM(quantidade)::numeric, 10)
      FROM carteira_ativos
               INNER JOIN
           operacoes ON operacoes.carteira_ativo_id = carteira_ativos.id
      WHERE carteira_ativos.carteira_id = #{id} AND operacoes.data <= '#{data_fim}'
      GROUP BY carteira_ativos.id
      HAVING ROUND(SUM(quantidade)::numeric, 10) <> 0
      ORDER BY book ASC;
    SQL

    ActiveRecord::Base.connection.execute(sql).values
  end

  def posicao_corretora(corretora)
    sql = <<~SQL
      SELECT ativos.nome, ROUND(SUM(quantidade)::numeric, 10), ativos.tipo
      FROM carteira_ativos
               INNER JOIN
           operacoes ON operacoes.carteira_ativo_id = carteira_ativos.id
               INNER JOIN
           ativos ON ativos.id = carteira_ativos.ativo_id
      WHERE carteira_ativos.carteira_id = #{id} AND corretora = '#{corretora}'
      GROUP BY ativos.tipo, ativos.nome
      HAVING ROUND(SUM(quantidade)::numeric, 10) <> 0
      ORDER BY ativos.tipo, ativos.nome ASC;
    SQL
    ActiveRecord::Base.connection.execute(sql).values
  end

end
