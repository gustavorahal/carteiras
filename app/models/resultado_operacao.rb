class ResultadoOperacao < ApplicationRecord
  self.table_name = "resultados_operacoes"
  belongs_to :operacao, inverse_of: :resultados_operacoes
  validates :quantidade_encerrada, numericality: { greater_than: 0 }
  validates :custos_alocados, numericality: { greater_than_or_equal_to: 0 }
end
