class FonteCotacao < ApplicationRecord
  self.table_name = "fontes_cotacao"
  include Arquivavel
  include Normalizavel

  has_many :cotacoes_ativos, class_name: "CotacaoAtivo", inverse_of: :fonte_cotacao
  has_many :cotacoes_cambio, class_name: "CotacaoCambio", inverse_of: :fonte_cotacao

  normaliza_texto :codigo, maiusculo: true
  normaliza_texto :nome
  validates :codigo, :nome, presence: true
  validates :codigo, uniqueness: true
  validate :codigo_imutavel_apos_referencia, on: :update

  private

  def codigo_imutavel_apos_referencia
    errors.add(:codigo, "não pode mudar após a primeira referência") if will_save_change_to_codigo? && (cotacoes_ativos.exists? || cotacoes_cambio.exists?)
  end
end
