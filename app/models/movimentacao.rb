class Movimentacao < ApplicationRecord
  belongs_to :carteira
  belongs_to :corretora
  belongs_to :extrato, optional: true

  def self.mes_a_mes(corretora = nil)
    query = order(data: :asc)
    if corretora
      query = query.where(corretora: corretora)
    end

    resultado = {}
    query.each do |row|
      if row.moeda == 'USD'
        valor = row.valor * CotacaoService.moedas('USDBRL', row.data)
      else
        valor = row.valor
      end

      current_month = row.data.end_of_month.to_date
      if resultado[current_month].present?
        resultado[current_month] += valor
      else
        resultado[current_month] = valor
      end
    end

    resultado
  end

  def self.total
    # aproveitamos o mtodo mes_a_mes porque o mesmo ja leva em consideracao diferentes moedas
    self.mes_a_mes.values.sum
  end

end
