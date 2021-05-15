class ContaCorrentePolicy < ApplicationPolicy

  def import?
    admin? || owner?
  end
end