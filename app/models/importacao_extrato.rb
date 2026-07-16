class ImportacaoExtrato < ApplicationRecord
  self.table_name = "importacoes_extrato"
  belongs_to :conta_caixa
  belongs_to :corretora
  has_many :itens, class_name: "ItemExtratoImportado", inverse_of: :importacao_extrato

  enum :estado, { normalizada: "normalizada", processando: "processando", concluida: "concluida", falhou: "falhou" }, validate: true
  validates :nome_original, :checksum_sha256, :formato, presence: true
  validates :checksum_sha256, uniqueness: { scope: :conta_caixa_id }
end
