class InvestidorPolicy < ApplicationPolicy
  def destroy? = false
  def arquivar? = edicao?
  def restaurar? = !record.espaco.arquivado? && (user&.administrador_sistema? || user&.pode_editar?(record.espaco))
end
