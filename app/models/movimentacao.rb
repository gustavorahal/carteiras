class Movimentacao < ApplicationRecord
  belongs_to :carteira
  belongs_to :corretora
  belongs_to :extrato, optional: true

  def self.mes_a_mes(corretora = nil)
    query = group(Arel.sql("DATE_TRUNC('month', data)")).order(Arel.sql("DATE_TRUNC('month', data)"))
    if corretora
      query = query.where(corretora: corretora)
    end
    resultado = query.sum(:valor)
    # DATE_TRUNC retorna inicio do mês quando na realidade a somatorio representa o final,
    # Além disso só queremos a data, remover hora... corrigir
    resultado_fix = {}
    resultado.each do |data, valor|
      resultado_fix[data.end_of_month.to_date] = valor
    end

    resultado_fix
  end

  def self.total
    sum :valor
  end

end
