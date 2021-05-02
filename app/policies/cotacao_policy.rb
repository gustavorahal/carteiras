class CotacaoPolicy < ApplicationPolicy

  def index?
    true
  end

  def show?
    true
  end

  # não existe o conceito de dono de cotação
  def owner?
    false
  end
end