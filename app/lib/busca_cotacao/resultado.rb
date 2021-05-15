module BuscaCotacao
  class Resultado

    attr_reader :preco, :data, :nome, :fonte

    def initialize(nome, preco, data, fonte)
      @nome = nome
      @preco = preco
      @data = data
      @fonte = fonte
    end
  end
end