require 'test_helper'

class BuscaBolsaMarketstackTest < ActiveSupport::TestCase
  test "busca cotacao BPAN4" do
    ticker = 'BPAN4'
    data = Date.new(2020,4,22)
    response = { "close" => 5.61 }.to_json

    with_env("MARKETSTACK_ACCESS_KEY" => "test-key") do
      Net::HTTP.stub(:get, response) do
        preco = BuscaCotacao::BolsaMarketstack.busca(ticker, data,'BVMF')
        assert_equal 5.61, preco
      end
    end
  end

  test "busca ultima cotacao AAPL" do
    ticker = 'AAPL'
    data = Date.today
    response = { "close" => 180.0 }.to_json

    with_env("MARKETSTACK_ACCESS_KEY" => "test-key") do
      Net::HTTP.stub(:get, response) do
        preco = BuscaCotacao::BolsaMarketstack.busca(ticker, data)
        assert_equal 180.0, preco
      end
    end
  end

end
