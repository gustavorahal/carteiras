class EventoFinanceiroPolicy < ApplicationPolicy
  def update? = (admin? || owner?) && record.rascunho?
  def edit? = update?
  def destroy? = update?
  def confirmar? = update?
  def reverter? = (admin? || owner?) && record.confirmado? && !record.revertido? && !record.reversao?
end
