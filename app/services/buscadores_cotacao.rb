class BuscadoresCotacao
  class << self
    def registrar(fonte, buscador)
      mutex.synchronize { registrados[fonte.to_s] = buscador }
    end

    def configurados
      mutex.synchronize { registrados.dup }
    end

    def limpar
      mutex.synchronize { registrados.clear }
    end

    private

    def registrados = @registrados ||= {}
    def mutex = @mutex ||= Mutex.new
  end
end
