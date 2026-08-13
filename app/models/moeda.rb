class Moeda < ApplicationRecord
  include Arquivavel
  include Normalizavel

  has_many :carteiras_base, class_name: "Carteira", foreign_key: :moeda_base_id, inverse_of: :moeda_base
  has_many :contas_caixa, class_name: "ContaCaixa", inverse_of: :moeda
  has_many :ativos, foreign_key: :moeda_negociacao_id, inverse_of: :moeda_negociacao

  normaliza_texto :codigo, maiusculo: true
  normaliza_texto :nome
  validates :codigo, format: { with: /\A[A-Z]{3}\z/ }, uniqueness: true
  validates :nome, presence: true
  validates :casas_decimais, inclusion: { in: 0..10 }
  validate :codigo_imutavel_apos_referencia, on: :update

  private

  def codigo_imutavel_apos_referencia
    return unless will_save_change_to_codigo?
    return unless contas_caixa.exists? || carteiras_base.exists? || ativos.exists? || CotacaoCambio.where("moeda_origem_id = ? OR moeda_destino_id = ?", id, id).exists?

    errors.add(:codigo, "não pode mudar após a primeira referência")
  end
end
