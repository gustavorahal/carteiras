require 'test_helper'

class BuscaYfinanceTest < ActiveSupport::TestCase
  test "busca ultima cotacao AAPL - exercitando get-quotes" do
    ticker = 'AAPL'
    data = Date.today

    preco = BuscaCotacao::BolsaYfinance.busca(ticker, data)
    assert_kind_of Float, preco
  end

  test "busca cotacao antiga AAPL - exercitando get-historical-data" do
    ticker = 'AAPL'
    data = Date.new(2022,2,15)

    preco = BuscaCotacao::BolsaYfinance.busca(ticker, data)
    assert_equal 172.7899932861328, preco
  end

end