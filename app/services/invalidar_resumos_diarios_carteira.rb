class InvalidarResumosDiariosCarteira
  def self.call(carteiras:, inicio:)
    Array(carteiras).each do |carteira|
      escopo = carteira.resumos_diarios.where(data: inicio..)
      next unless escopo.exists?
      fim = escopo.maximum(:data)
      escopo.delete_all
      RecalcularResumosDiariosJob.perform_later(carteira, inicio, fim)
    end
  end
end
