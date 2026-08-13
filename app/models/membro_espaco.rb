class MembroEspaco < ApplicationRecord
  self.table_name = "membros_espaco"

  PAPEIS = %w[administrador editor leitor].freeze

  belongs_to :espaco, inverse_of: :membros_espaco
  belongs_to :user, inverse_of: :membros_espaco

  validates :papel, inclusion: { in: PAPEIS }
  validates :user_id, uniqueness: { scope: :espaco_id }
  validate :espaco_disponivel, on: :create
  before_update :proteger_rebaixamento_do_ultimo_administrador
  before_destroy :proteger_remocao_do_ultimo_administrador

  private

  def espaco_disponivel
    errors.add(:espaco, "está arquivado") if espaco&.arquivado?
  end

  def proteger_rebaixamento_do_ultimo_administrador
    return unless papel_in_database == "administrador" && papel != "administrador"
    proteger_ultimo_administrador
  end

  def proteger_remocao_do_ultimo_administrador
    return unless papel == "administrador"
    proteger_ultimo_administrador
  end

  def proteger_ultimo_administrador
    espaco.with_lock do
      if espaco.membros_espaco.where(papel: "administrador").where.not(id:).none?
        errors.add(:papel, "não é possível remover ou rebaixar o último administrador")
        throw :abort
      end
    end
  end
end
