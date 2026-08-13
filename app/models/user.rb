class User < ApplicationRecord
  devise :database_authenticatable, :recoverable, :rememberable, :validatable, :trackable, :lockable

  has_many :membros_espaco, class_name: "MembroEspaco", inverse_of: :user
  has_many :espacos, through: :membros_espaco
  has_many :transacoes_criadas, class_name: "TransacaoFinanceira", foreign_key: :criado_por_id, inverse_of: :criado_por
  has_many :transacoes_confirmadas, class_name: "TransacaoFinanceira", foreign_key: :confirmado_por_id, inverse_of: :confirmado_por

  def papel_no(espaco)
    return "administrador" if administrador_sistema?

    membros_espaco.find { |membro| membro.espaco_id == espaco.id }&.papel ||
      membros_espaco.find_by(espaco_id: espaco.id)&.papel
  end

  def pode_ler?(espaco)
    administrador_sistema? || papel_no(espaco).present?
  end

  def pode_editar?(espaco)
    administrador_sistema? || %w[administrador editor].include?(papel_no(espaco))
  end

  def pode_administrar?(espaco)
    administrador_sistema? || papel_no(espaco) == "administrador"
  end
end
