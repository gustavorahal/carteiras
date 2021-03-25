class Movimentacao < ApplicationRecord
  belongs_to :carteira
  belongs_to :corretora
  belongs_to :extrato

  def self.mes_a_mes
    group(Arel.sql("DATE_TRUNC('month', data)")).order(Arel.sql("DATE_TRUNC('month', data)")).sum(:valor)
  end

  def self.total
    sum :valor
  end

end
