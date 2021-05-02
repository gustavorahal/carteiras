class ContaCorrentePolicy < ApplicationPolicy

  def owner?
    return false if record.is_a? Symbol

    user&.investidor.id == record.carteira.investidor.id
  end
end