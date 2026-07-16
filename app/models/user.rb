class User < ApplicationRecord
  devise :database_authenticatable, :recoverable, :rememberable, :validatable, :trackable, :lockable

  has_one :investidor, inverse_of: :user
  has_many :eventos_financeiros, class_name: "EventoFinanceiro", foreign_key: :usuario_responsavel_id, inverse_of: :usuario_responsavel

  enum :role, { admin: 0, investidor: 1 }
end
