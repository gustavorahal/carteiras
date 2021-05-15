
module BuscaCotacao
  class Facade

    # @return [Resultado]
    def self.tesouro(nome, data)
      # DESABILITANDO, DEIXANDO COMO REFERÊNCIA CASO QUEIRA RETOMAR NUM FUTURO PROXIMO
      # VAMOS DEIXAR MAIS BUSCAS ACONTECENDO NO BACKEND MESMO, PACIÊNCIA POR ORA
      #
      # Pela maneira como o Backend funciona, esta função faz algo
      # atipico. Aproveitando que a busca é custosa (download de arquivo como dados de todo ano)
      # e retorna informações de todos data, vamos aproveitar e atualizar
      # informações para várias data
      #
      # dados = BuscaCotacao::Tesouro.busca ativo.nome, data
      # dados.each do |data_api, preco|
      #   cotacao = Cotacao.find_by(ativo_id: ativo.id, valor_unit: preco, data: data_api)
      #   Cotacao.create!(ativo_id: ativo.id, valor_unit: preco, data: data_api, fonte: 'tesouro_gov') if cotacao.blank?
      # end

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
      tentativas = 3
      data_efetiva = data
      while preco.blank?
        if tentativas.zero?
          preco = nil
          break
        else
          data_efetiva -= 1.day
          preco, fonte = BuscaCotacao::Bolsa.busca(ticker, data_efetiva, bolsa)
          Rails.logger.info("Facade.bolsa: Tentando nova cotação para #{ticker} na data #{data_efetiva}")
          tentativas -= 1
        end
      end

      if preco
        return Resultado.new(ticker, preco, data_efetiva, fonte)
      end

      nil
    end

  end
end
