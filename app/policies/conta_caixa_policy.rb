class ContaCaixaPolicy < ApplicationPolicy
  def destroy? = false
  def arquivar? = edicao?
  def restaurar? = !record.espaco.arquivado? && !record.conta_investimento.arquivado? && !record.carteira.arquivado? && !record.investidor.arquivado? &&
    (user&.administrador_sistema? || user&.pode_editar?(record.espaco))
end
