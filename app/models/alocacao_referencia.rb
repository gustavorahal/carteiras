class AlocacaoReferencia < ApplicationRecord
  self.table_name = "alocacoes_referencia"
  belongs_to :versao_referencia, inverse_of: :alocacoes
  belongs_to :ativo

  validates :categoria, presence: true
  validates :ativo_id, uniqueness: { scope: :versao_referencia_id }
  validates :percentual, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  before_create :impedir_alteracao_historica
  before_update :impedir_alteracao_historica
  before_destroy :impedir_alteracao_historica

  private

  def impedir_alteracao_historica
    return unless versao_referencia&.estado.in?(%w[publicada encerrada])
    errors.add(:base, "Alocações publicadas são imutáveis")
    throw :abort
  end
end
