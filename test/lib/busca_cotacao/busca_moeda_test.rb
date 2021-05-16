require 'test_helper'

class BuscaMoedaTest < ActiveSupport::TestCase
  test "busca USDBRL em data válida" do
    resultado = BuscaCotacao::Moeda.busca('USDBRL', Date.new(2021,4,19))
    assert_equal [5.5744, "bcb_gov"], resultado
  end

  test "busca USDBRL em data INválida" do
    resultado = BuscaCotacao::Moeda.busca('USDBRL', Date.new(2021,4,17))
    assert_nil resultado
  end

  test "busca cotacao moeda que não existe" do
    assert_raises RuntimeError do
      BuscaCotacao::Moeda.busca('NAOEXISTE', Date.new(2021,4,19))
    end
  end

  test "busca BTCBRL em data válida" do
    resultado = BuscaCotacao::Moeda.busca('BTCBRL', Date.new(2021,4,19))

    # FIXME: nosso backend só pega cotacao de 'agora' portanto
    # só temos que verificar que algum resultado foi retornado
    assert_equal 'coingecko_rapidapi', resultado[1]
  end

end