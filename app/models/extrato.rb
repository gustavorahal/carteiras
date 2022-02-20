class Extrato < ApplicationRecord
  belongs_to :conta_corrente
  has_one :provento, dependent: :destroy
  has_one :movimentacao, dependent: :destroy

  def to_s
    "Extrato ID##{id}"
  end
end
