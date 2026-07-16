class ReferenciaPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      user.present? ? scope.all : scope.none
    end
  end

  def index? = user.present?
  def show? = user.present?
  def create? = admin?
  def update? = admin?
  def destroy? = admin?
end
