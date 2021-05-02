class Investidor < ApplicationRecord
  has_many :carteiras
  belongs_to :user
end
