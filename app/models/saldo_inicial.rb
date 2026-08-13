class SaldoInicial < ApplicationRecord
  self.table_name = "saldos_iniciais"
  include FatoFinanceiroImutavel

  FONTES_CUSTO = %w[manual xp avenue planilha outra].freeze

  belongs_to :transacao_financeira, inverse_of: :saldo_inicial
  belongs_to :conta_investimento, inverse_of: :saldos_iniciais
  belongs_to :ativo, inverse_of: :saldos_iniciais

  validates :quantidade, numericality: { greater_than: 0 }
  validates :custo_total_local, :custo_total_base, numericality: { greater_than_or_equal_to: 0 }
  validates :fonte_custo, inclusion: { in: FONTES_CUSTO }
  validates :preco_medio_local_informado, :preco_medio_base_informado,
    numericality: { greater_than: 0 }, allow_nil: true
  validate :precos_medios_preenchidos_em_conjunto

  private

  def precos_medios_preenchidos_em_conjunto
    return if preco_medio_local_informado.nil? == preco_medio_base_informado.nil?

    errors.add(:preco_medio_base_informado, "deve ser informado junto com o preço médio local")
  end
end
