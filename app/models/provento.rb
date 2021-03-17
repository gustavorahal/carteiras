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
    if evento
      where(evento: evento).group("DATE_TRUNC('month', data)").order("DATE_TRUNC('month', data)").sum(:valor_liquido)
    else
      group("DATE_TRUNC('month', data)").order("DATE_TRUNC('month', data)").sum(:valor_liquido)
    end
  end

end
