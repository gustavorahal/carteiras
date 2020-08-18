class Extrato < ApplicationRecord
  belongs_to :investidor
  belongs_to :corretora

end
