class Carteira < ApplicationRecord
  has_many :carteira_ativos
  belongs_to :investidor

  # Quais ativos eu tenho na carteira até determinada data?
  #
  # Retorna um array de ativos da carteira com as seguintes informações:
  # ativo_id, nome, descrição, book, quantidade, cotacao USDBRL e carteira_ativo_id
  def posicao(data_fim)
    # Para isso somamos a quantidade que temos de cada ativo
    # e o que for diferente de zero significa que temos o ativo na carteira.
    # Quantidade pode ser negativo. Exemplo: operação de short
    sql = <<~SQL
      SELECT carteira_ativos.ativo_id, ativos.nome, ativos.descricao, carteira_ativos.book,
             ROUND(SUM(quantidade)::numeric, 10), operacoes.usdbrl, carteira_ativos.id
      FROM operacoes
               INNER JOIN
           carteira_ativos ON operacoes.carteira_ativo_id = carteira_ativos.id
               INNER JOIN
           ativos ON carteira_ativos.ativo_id = ativos.id
      WHERE carteira_ativos.carteira_id = #{id} AND
          operacoes.data <= '#{data_fim}'
      GROUP BY ativos.nome, carteira_ativos.ativo_id, ativos.descricao, carteira_ativos.book, operacoes.usdbrl, carteira_ativos.id
      HAVING ROUND(SUM(quantidade)::numeric, 10) <> 0
      ORDER BY carteira_ativos.book, ativos.nome ASC;
    SQL

    ActiveRecord::Base.connection.execute(sql).values
  end

end
