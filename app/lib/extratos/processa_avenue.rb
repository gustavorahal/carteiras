module Extratos
  class ProcessaAvenue < ProcessaBase

    def self.dividendo(texto)
      # Exemplo:
      regex_dividendo = %r{}
      nil
    end

    def self.jcp(texto)
      # Exemplos:
      #
      regex_jcp = %r{}
      nil
    end

    def self.rendimento(texto)
      # Exemplo:
      regex_rendimento = %r{}
      nil
    end

    def self.resgate?(texto)
      nil
    end

    def self.aporte?(texto)
      # Exemplos:
      # Ted Recebido. Origem Banco : 1 Agencia : 4858 Conta: 503770
      regex_aporte = %r{Ted Recebido. Origem .*}
      match = regex_aporte.match(texto)
      match ? true : false
    end


  end
end