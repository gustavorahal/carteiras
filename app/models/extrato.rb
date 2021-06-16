class Extrato < ApplicationRecord
  belongs_to :conta_corrente

  def to_s
    "Extrato ID##{id}"
  end
end
