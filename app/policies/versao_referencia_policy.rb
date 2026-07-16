class VersaoReferenciaPolicy < ApplicationPolicy
  def index? = user.present?
  def show? = user.present?
  def create? = admin?
  def update? = admin? && record.rascunho?
  def publicar? = update?
end
