class EspacoPolicy < ApplicationPolicy
  def create? = user.present?
  def update? = administracao?
  def destroy? = false
  def arquivar? = administracao?
  def restaurar? = user&.administrador_sistema? || user&.pode_administrar?(record)
end
