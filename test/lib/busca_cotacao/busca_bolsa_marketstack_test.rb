require 'test_helper'

class BuscaBolsaMarketstackTest < ActiveSupport::TestCase
  test "busca cotacao BPAN4" do
    ticker = 'BPAN4'
    data = Date.new(2020,4,22)

    preco = BuscaCotacao::BolsaMarketstack.busca(ticker, data,'BVMF')
    assert_equal 5.61, preco
  end

  test "busca ultima cotacao AAPL" do
    ticker = 'AAPL'
    data = Date.today

    preco = BuscaCotacao::BolsaMarketstack.busca(ticker, data)
  end

end