class VersaoReferencia < ApplicationRecord
  self.table_name = "versoes_referencia"
  belongs_to :referencia, inverse_of: :versoes
  has_many :alocacoes, class_name: "AlocacaoReferencia", inverse_of: :versao_referencia

  enum :estado, { rascunho: "rascunho", publicada: "publicada", encerrada: "encerrada" }, validate: true
  validates :vigencia_inicial, presence: true, uniqueness: { scope: :referencia_id }
  before_update :impedir_alteracao_historica
  before_destroy :impedir_alteracao_historica
  scope :publicadas, -> { where(estado: "publicada") }
  scope :historicas, -> { where(estado: %w[publicada encerrada]) }

  private

  def impedir_alteracao_historica
    return unless estado_in_database.in?(%w[publicada encerrada])
    errors.add(:base, "Versões publicadas ou encerradas são imutáveis")
    throw :abort
  end
end
