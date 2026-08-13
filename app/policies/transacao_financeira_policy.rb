class TransacaoFinanceiraPolicy < ApplicationPolicy
  def update? = edicao? && record.rascunho?
  def destroy? = update?
  def confirmar? = update?
  def reverter? = edicao? && record.confirmada? && !record.reversao?
  def corrigir? = reverter?
end
