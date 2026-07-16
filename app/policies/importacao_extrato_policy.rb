class ImportacaoExtratoPolicy < ApplicationPolicy
  def owner?
    user&.investidor && user.investidor.id == record.conta_caixa.carteira.investidor_id
  end
end
