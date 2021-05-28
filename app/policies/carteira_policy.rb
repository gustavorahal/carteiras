class CarteiraPolicy < ApplicationPolicy

  def ganho_de_capital?
    admin? || owner?
  end

  def posicao_ano_anterior?
    admin? || owner?
  end
end