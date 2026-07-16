class LancamentoCaixa < ApplicationRecord
  self.table_name = "lancamentos_caixa"
  include ConfirmadoImutavel
  belongs_to :evento_financeiro, inverse_of: :lancamentos_caixa
  belongs_to :conta_caixa, inverse_of: :lancamentos_caixa

  validates :data_efetiva, :natureza, presence: true
  validates :valor, numericality: { other_than: 0 }
  validates :natureza, uniqueness: { scope: %i[evento_financeiro_id conta_caixa_id] }
end
