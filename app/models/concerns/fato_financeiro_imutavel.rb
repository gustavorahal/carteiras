module FatoFinanceiroImutavel
  extend ActiveSupport::Concern

  included do
    before_create :impedir_adicao_a_confirmado
    before_update :impedir_alteracao_de_confirmado
    before_destroy :impedir_exclusao_de_confirmado
  end

  private

  def impedir_adicao_a_confirmado
    return if is_a?(TransacaoFinanceira)
    return if TransacoesFinanceiras::Interno.escrita_derivada_permitida?
    return unless transacao_financeira&.confirmada?

    errors.add(:base, "fato financeiro confirmado é imutável")
    throw :abort
  end

  def impedir_alteracao_de_confirmado
    transacao = is_a?(TransacaoFinanceira) ? self : transacao_financeira
    return unless transacao&.estado_anterior_confirmado?

    errors.add(:base, "fato financeiro confirmado é imutável")
    throw :abort
  end

  def impedir_exclusao_de_confirmado
    transacao = is_a?(TransacaoFinanceira) ? self : transacao_financeira
    return unless transacao&.confirmada?

    errors.add(:base, "fato financeiro confirmado é imutável")
    throw :abort
  end
end
