class ContaCorrente < ApplicationRecord
  has_many :extratos
  belongs_to :corretora
  belongs_to :investidor

  validates :investidor_id, uniqueness: { scope: [ :moeda, :corretora_id ] }

  def saldo
    extratos.sum(:valor)
  end

end
