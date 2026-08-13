module Arquivavel
  extend ActiveSupport::Concern

  included do
    scope :ativos, -> { where(arquivado_em: nil) }
    validate :impedir_restauracao_sob_ancestral_arquivado
  end

  def arquivado?
    arquivado_em.present?
  end

  def arquivar!
    update!(arquivado_em: Time.current)
  end

  def restaurar!
    update!(arquivado_em: nil)
  end

  private

  def impedir_restauracao_sob_ancestral_arquivado
    return unless will_save_change_to_arquivado_em? && arquivado_em.nil?

    ancestral = %i[espaco investidor carteira conta_investimento].filter_map do |associacao|
      public_send(associacao) if respond_to?(associacao)
    end.reject { |registro| registro.equal?(self) }.find(&:arquivado?)
    errors.add(:arquivado_em, "não pode ser restaurado enquanto #{ancestral.class.model_name.human.downcase} estiver arquivado") if ancestral
  end
end
