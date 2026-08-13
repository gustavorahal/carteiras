class MembroEspacoPolicy < ApplicationPolicy
  def create? = administracao?
  def update? = administracao?
  def destroy? = administracao?

  private

  def espaco = record.espaco
end
