class CotacaoPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      (user&.admin? || user&.investidor?) ? scope.all : scope.none
    end
  end

  def index?
    true
  end

  def show?
    true
  end

  # não existe o conceito de dono de cotação
  def owner?
    false
  end
end
