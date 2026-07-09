class User < ApplicationRecord
  # Include devise modules. Others available are:
  # :confirmable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable, :trackable, :lockable

  has_one :investidor

  enum :role, {
    admin: 1,
    investidor: 2
  }

end
