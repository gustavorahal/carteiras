module Financeiro
  def self.congelar(valor)
    case valor
    when Hash
      valor.each { |chave, item| congelar(chave); congelar(item) }
    when Array
      valor.each { |item| congelar(item) }
    end
    valor.freeze
  end

  class Erro < StandardError
    attr_reader :codigo, :detalhes

    def initialize(codigo, detalhes = {})
      @codigo = codigo.to_s
      @detalhes = Financeiro.congelar(detalhes.deep_dup)
      super(@codigo.humanize)
    end
  end

  class NaoAutorizado < Erro
    def initialize(detalhes = {}) = super(:nao_autorizado, detalhes)
  end

  class EscopoInvalido < Erro
    def initialize(detalhes = {}) = super(:escopo_invalido, detalhes)
  end

  class AtributosInvalidos < Erro
    def initialize(detalhes = {}) = super(:atributos_invalidos, detalhes)
  end

  class EstadoInvalido < Erro
    def initialize(detalhes = {}) = super(:estado_invalido, detalhes)
  end

  class HistoricoInvalido < Erro
    def initialize(detalhes = {}) = super(:historico_invalido, detalhes)
  end

  class RegistroArquivado < Erro
    def initialize(detalhes = {}) = super(:registro_arquivado, detalhes)
  end

  class ConflitoIdempotencia < Erro
    def initialize(detalhes = {}) = super(:conflito_idempotencia, detalhes)
  end
end
