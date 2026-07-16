class ConsultarRentabilidade
  def self.call(carteira:, inicio:, fim: Date.current)
    resumos = carteira.resumos_diarios.where(data: inicio..fim).order(:data).to_a
    datas_esperadas = resumos.empty? ? [] : (resumos.first.data..fim).to_a
    periodo_completo = resumos.none?(&:incompleto?) && resumos.map(&:data) == datas_esperadas
    retornos = resumos.select(&:completo?)
    retorno = if periodo_completo
      retornos.reduce(1.to_d) { |produto, resumo| produto * (1 + resumo.twr_diario) } - 1
    end
    { resumos:, retorno:, completo: periodo_completo }
  end
end
