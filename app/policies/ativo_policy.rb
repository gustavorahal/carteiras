
class AtivoPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      (user&.admin? || user&.investidor?) ? scope.all : scope.none
    end
  end

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
