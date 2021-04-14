module Extratos
  # Já estando o extrato importado para tabela extratos
  # agora vamos processar, ou seja, ler as informações e inseri-las no sistema
  class ProcessaBase

    # @return hash [nome_ativo, quantidade]
    def self.dividendo(texto)
      raise NotImplementedError
    end

    # @return hash [nome_ativo, quantidade]
    def self.jcp(texto)
      raise NotImplementedError
    end

    # @return hash [nome_ativo, quantidade]
    def self.rendimento(texto)
      raise NotImplementedError
    end

    def self.resgate?(texto)
      raise NotImplementedError
    end

    def self.aporte?(texto)
      raise NotImplementedError
    end

  end
end