class Provento < ApplicationRecord
  self.table_name = "proventos"
  include ConfirmadoImutavel

  belongs_to :evento_financeiro, inverse_of: :provento
  belongs_to :conta_investimento
  belongs_to :ativo
  belongs_to :moeda

  enum :tipo, { dividendo: "dividendo", jcp: "jcp", rendimento: "rendimento" }, validate: true

  validates :quantidade_referencia, :valor_bruto, :tributos, :valor_liquido,
    numericality: { greater_than_or_equal_to: 0 }
  validates :taxa_conversao_base, :taxa_conversao_fiscal, numericality: { greater_than: 0 }
  validate :valor_liquido_coerente

  private

  def valor_liquido_coerente
    return if valor_bruto.nil? || tributos.nil? || valor_liquido.nil?
    errors.add(:valor_liquido, "deve ser igual ao bruto menos tributos") unless valor_liquido == valor_bruto - tributos
  end
end
