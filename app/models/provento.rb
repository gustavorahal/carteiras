class Provento < ApplicationRecord
  include FatoFinanceiroImutavel

  belongs_to :transacao_financeira, inverse_of: :provento
  belongs_to :conta_caixa
  belongs_to :ativo, inverse_of: :proventos

  validates :tipo, inclusion: { in: %w[dividendo jcp rendimento juros outro] }
  validates :data_base, :data_pagamento, presence: true
  validates :quantidade_referencia, :valor_bruto, :retencoes, :valor_liquido, numericality: { greater_than_or_equal_to: 0 }
  validates :taxa_conversao_base, numericality: { greater_than: 0 }
end
