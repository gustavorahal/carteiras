class Provento < ApplicationRecord
  belongs_to :ativo
  belongs_to :carteira
  belongs_to :corretora
  belongs_to :extrato

  enum evento: {
    dividendo: 1,
    jcp: 2,
    rendimento: 3
  }

  def self.mes_a_mes(evento = nil)
    query = group(Arel.sql("DATE_TRUNC('month', data)")).order(Arel.sql("DATE_TRUNC('month', data)"))
    query = query.where(evento: evento) if evento

    resultado = query.sum(:valor_liquido)
    # DATE_TRUNC retorna inicio do mês quando na realidade a somatorio representa o final,
    # Além disso só queremos a data, remover hora... corrigir
    resultado_fix = {}
    resultado.each do |data, valor|
      resultado_fix[data.end_of_month.to_date] = valor
    end

    resultado_fix
  end

end
