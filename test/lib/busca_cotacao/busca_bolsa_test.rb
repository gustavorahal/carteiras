require 'test_helper'

class BuscaBolsaTest < ActiveSupport::TestCase

  test 'busca cotacao APPL hoje' do
    preco = BuscaCotacao::Bolsa.busca("AAPL", nil, Date.today)
    assert_kind_of Float, preco[0]
  end

  test 'busca cotacao APPL em data passada' do
    preco = BuscaCotacao::Bolsa.busca("AAPL", nil, Date.new(2022,2,15))
    assert_equal 172.79, preco[0]
  end

end