
class AtivoPolicy < ApplicationPolicy

  def index?
    user&.admin? || user&.investidor?
  end

  def show?
    user&.admin? || user&.investidor?
  end

  # não existe o conceito de dono de ativo
  def owner?
    false
  end
end