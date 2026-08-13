class CatalogoGlobalPolicy < ApplicationPolicy
  def index? = user.present?
  def show? = user.present?
  def create? = user&.administrador_sistema?
  def update? = user&.administrador_sistema? && !record.arquivado?
  def destroy? = false
  def arquivar? = user&.administrador_sistema?
  def restaurar? = user&.administrador_sistema?

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user&.administrador_sistema?
      user ? scope.where(arquivado_em: nil) : scope.none
    end
  end
end
