# Posição da Carteira em determinada data.
# Quais ativos e qual a posicao deles
class Posicao

  def initialize(carteira, data)
    @carteira = carteira # ActiveRecord Carteira
    @data = data > Date.today ? Date.today : data
    @investidor = carteira.investidor
  end

  def ativos
    AtivoPosicao.includes(:ativos).where(carteira: @carteira, data: @data).pluck(:ativo)
  end

  def corretoras
    AtivoPosicao.where(carteira: @carteira, data: @data).distinct(:corretora)
  end

  def por_corretora

  end

  # Quais ativos eu tenho na carteira até determinada data?
  #
  # @return: lista com tuplas [ativo_id, quantidade]
  def calcula_posicao
    data_str = @data.strftime '%F'
    # Para isso somamos a quantidade que temos de cada ativo
    # e o que for diferente de zero significa que temos o ativo na carteira.
    # Quantidade pode ser negativo, por exemplo, operação de short
    sql = <<~SQL
    SELECT ativos.id, ROUND(SUM(quantidade)::numeric, 10)
    FROM ativos
    JOIN operacoes ON operacoes.ativo_id = ativos.id
    WHERE
        operacoes.carteira_id = #{@carteira.id} AND
        operacoes.data::date <= '#{data_str}'
    GROUP BY ativos.id, ativos.nome
    HAVING ROUND(SUM(quantidade)::numeric, 10) <> 0
    ORDER BY ativos.nome ASC;
    SQL

    ActiveRecord::Base.connection.execute(sql).values
  end

end