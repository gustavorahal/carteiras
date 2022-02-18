
module BuscaCotacao
  class Facade

    # @return [Resultado]
    def self.tesouro(nome, data)
      dados = BuscaCotacao::Tesouro.busca nome, data
      return if dados.nil?

      dados.each do |data_api, preco|
        return Resultado.new(nome, preco, data_api,'tesouro_gov') if data_api == data
      end

      nil
    end

    # @return [Resultado]: é possivel que data do resultado seja diferente da solicitada.
    def self.bolsa(ticker, moeda, data)
      bolsa = ('BVMF' if moeda == 'BRL')
      preco, fonte = BuscaCotacao::Bolsa.busca(ticker, bolsa, data)
      # infelizmente nossa API é cheia de furos, com informações não disponíveis para determinadas datas
      # tentativas = 3
      # data_efetiva = data
      # while preco.blank?
      #   if tentativas.zero?
      #     preco = nil
      #     break
      #   else
      #     data_efetiva -= 1.day
      #     preco, fonte = BuscaCotacao::Bolsa.busca(ticker, bolsa, data_efetiva)
      #     Rails.logger.info("Facade.bolsa: Tentando nova cotação para #{ticker} na data #{data_efetiva}")
      #     tentativas -= 1
      #   end
      # end

      return Resultado.new(ticker, preco, data, fonte) if preco

      nil
    end

    # @return [Resultado]
    def self.fundo(cnpj, data)
      valor_cota = BuscaCotacao::Fundo.busca(cnpj, data)
      return Resultado.new(cnpj, valor_cota, data, 'cvm_gov') if valor_cota

      nil
    end

    # @return [Resultado]
    def self.moeda(de_para, data)
      preco, fonte = BuscaCotacao::Moeda.busca(de_para, data)
      return Resultado.new(de_para, preco, data, fonte) if preco

      nil
    end

  end
end
