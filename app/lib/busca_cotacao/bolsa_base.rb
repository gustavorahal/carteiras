
module BuscaCotacao
  class BolsaBase

    # Busca cotacao para ticker bolsa
    #
    # @param ticker: [String] nome do ativo
    # @param data: [Date] ou nil caso seja a cotacao atual
    # @return [BigDecimal] valor do ativo na data especificada
    def self.busca(ticker, bolsa, data)
      throw NotImplementedError
    end

    # Dado um ticket name, arrumar considerando o que a API espera
    # suas especificidades
    #
    # @return ticker com nome corrigido, se for o caso
    def self.ticker_fix(ticker)
      throw NotImplementedError
    end

  end
end
