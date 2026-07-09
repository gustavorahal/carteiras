module BuscaCotacao
  class Resultado

    attr_reader :preco, :data, :nome, :fonte

    def initialize(nome, preco, data, fonte)
      @nome = nome
      @preco = Utils.decimal(preco)
      @data = data
      @fonte = fonte
    end
  end
end
