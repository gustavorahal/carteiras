class Espaco < ApplicationRecord
  include Arquivavel
  include Normalizavel

  has_many :membros_espaco, class_name: "MembroEspaco", inverse_of: :espaco
  has_many :users, through: :membros_espaco
  has_many :investidores, inverse_of: :espaco

  normaliza_texto :nome
  validates :nome, presence: true

  def adicionar_primeiro_administrador!(user)
    with_lock do
      membros_espaco.create!(user:, papel: "administrador") if membros_espaco.empty?
    end
  end
end
