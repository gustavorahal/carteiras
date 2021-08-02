require 'test_helper'

class BuscaBolsaTest < ActiveSupport::TestCase
  test "busca cotacao BPAN4 marketstack" do
    ticker = 'BPAN4'
    data = Date.new(2020,4,22)

    preco = BuscaCotacao::Bolsa._api_marketstack(ticker, data,'BVMF')
    assert_equal 5.61, preco
  end

  test "busca cotacao BPAN4 yahoo finance" do
    ticker = 'BPAN4'
    data = Date.new(2020,4,22)

    preco = BuscaCotacao::Bolsa._api_yahoo_finance(ticker, data,'BVMF')
    assert_equal 5.61, preco
  end
end