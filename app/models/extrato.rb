class Extrato < ApplicationRecord
  belongs_to :conta_corrente
  has_one :provento, dependent: :destroy
  has_one :detalhe_movimentacao, class_name: :Movimentacao, dependent: :destroy

  def to_s
    "Extrato ID##{id}"
  end
end
