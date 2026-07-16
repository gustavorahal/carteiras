class ResumoDiarioCarteira < ApplicationRecord
  self.table_name = "resumos_diarios_carteira"
  belongs_to :carteira, inverse_of: :resumos_diarios
  enum :estado_completude, {
    completo: "completo", incompleto: "incompleto", sem_patrimonio_inicial: "sem_patrimonio_inicial"
  }, validate: true
  validates :data, presence: true, uniqueness: { scope: :carteira_id }
end
