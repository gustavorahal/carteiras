class Operacao < ApplicationRecord
  self.table_name = "operacoes"
  include ConfirmadoImutavel

  belongs_to :evento_financeiro, inverse_of: :operacao
  belongs_to :conta_investimento
  belongs_to :ativo
  belongs_to :moeda
  has_many :resultados_operacoes, class_name: "ResultadoOperacao", inverse_of: :operacao

  enum :natureza, { compra: "compra", venda: "venda" }, validate: true

  validates :quantidade, :preco_unitario, :taxa_conversao_base, :taxa_conversao_fiscal,
    numericality: { greater_than: 0 }
  validates :taxa, :emolumentos, :corretagem, :iss_iof, :irrf, :outros,
    numericality: { greater_than_or_equal_to: 0 }
  validates :data_negociacao, :data_liquidacao, presence: true
  validate :moeda_deve_ser_a_do_ativo

  def custos_operacionais
    taxa + emolumentos + corretagem + iss_iof + irrf + outros
  end

  def valor_bruto = quantidade * preco_unitario

  private

  def moeda_deve_ser_a_do_ativo
    errors.add(:moeda, "deve ser a moeda de negociação do ativo") if ativo && moeda != ativo.moeda_negociacao
  end
end
