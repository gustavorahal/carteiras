class Movimentacao < ApplicationRecord
  belongs_to :carteira
  belongs_to :corretora
  belongs_to :extrato

  def self.mes_a_mes
    group("DATE_TRUNC('month', data)").order("DATE_TRUNC('month', data)").sum(:valor)
  end

  def self.total
    sum :valor
  end

end
