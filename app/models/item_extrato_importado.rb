class ItemExtratoImportado < ApplicationRecord
  self.table_name = "itens_extrato_importado"
  belongs_to :importacao_extrato, inverse_of: :itens
  belongs_to :moeda
  belongs_to :evento_financeiro, optional: true
  belongs_to :lancamento_caixa, optional: true
  belongs_to :usuario_responsavel, class_name: "User", optional: true

  enum :estado_conciliacao, {
    pendente: "pendente", conciliado: "conciliado", evento_criado: "evento_criado",
    ambiguo: "ambiguo", ignorado: "ignorado"
  }, validate: true
  validates :ordem, uniqueness: { scope: :importacao_extrato_id }
  validate :vinculo_exclusivo

  private

  def vinculo_exclusivo
    errors.add(:base, "O item não pode apontar para evento e lançamento ao mesmo tempo") if evento_financeiro && lancamento_caixa
  end
end
