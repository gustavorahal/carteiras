require 'open-uri' # para 'open' não conflitar com Kernel.open
require 'net/http'

module BuscaCotacao
  class Bolsa

    # @return: [preco, fonte]
    def self.busca(ticker, bolsa, data)
      preco, fonte = _api_busca(ticker, data, bolsa)
      return [preco, fonte] unless preco.blank?

      nil
    end


    #
    # Privado
    #

    def self._api_busca(ticker, data, bolsa)
      preco = nil

      begin
        # As cotações do Market Stack são mais corretas do que as do yFinance
        # yFinance esta praticamente sem dados do Brasil tb
        preco = BolsaMarketstack.busca(ticker, data, bolsa)
      rescue StandardError => e
        Rails.logger.info("BuscaAtivos::Bolsa._api_busca: #{e.message}")
      end

      return [preco, 'marketstack'] unless preco.nil?

      begin
        preco = BolsaYfinance.busca(ticker, data, bolsa)
      rescue StandardError => e
        Rails.logger.info("BuscaAtivos::Bolsa._api_busca: #{e.message}")
      end

      [preco, 'yahoo_finance_rapidapi']
    end

  end
end