class Investidor < ApplicationRecord
  belongs_to :user, inverse_of: :investidor
  belongs_to :moeda_fiscal, class_name: "Moeda"
  has_many :carteiras, inverse_of: :investidor

  validates :nome, presence: true
end
