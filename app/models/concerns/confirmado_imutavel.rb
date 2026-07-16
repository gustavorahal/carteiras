module ConfirmadoImutavel
  extend ActiveSupport::Concern

  included do
    validate :tipo_deve_corresponder_ao_evento
    before_create :impedir_inclusao_em_evento_confirmado
    before_update :impedir_alteracao_confirmada
    before_destroy :impedir_exclusao_confirmada
  end

  private

  def tipo_deve_corresponder_ao_evento
    return if is_a?(LancamentoCaixa)
    tipo_esperado = self.class.model_name.element
    return if evento_financeiro&.tipo == tipo_esperado
    errors.add(:evento_financeiro, "deve possuir o tipo #{tipo_esperado}")
  end

  def impedir_inclusao_em_evento_confirmado
    return unless evento_financeiro&.confirmado? && !evento_financeiro.confirmacao_em_curso?
    errors.add(:base, "Não é possível acrescentar fatos a um evento confirmado")
    throw :abort
  end

  def impedir_alteracao_confirmada
    return unless evento_financeiro&.confirmado?
    errors.add(:base, "Fatos financeiros confirmados são imutáveis")
    throw :abort
  end

  def impedir_exclusao_confirmada = impedir_alteracao_confirmada
end
