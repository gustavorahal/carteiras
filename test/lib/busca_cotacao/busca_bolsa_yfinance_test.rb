require 'test_helper'

class BuscaYfinanceTest < ActiveSupport::TestCase
  test "busca ultima cotacao AAPL - exercitando get-quotes" do
    ticker = 'AAPL'
    data = Date.today
    json_response = { "quoteResponse" => { "result" => [{ "regularMarketPrice" => 180.0 }] } }

    Utils.stub(:fetch_rapidapi_json, json_response) do
      preco = BuscaCotacao::BolsaYfinance.busca(ticker, data)
      assert_equal 180.0, preco
    end
  end

  test "busca cotacao antiga AAPL - exercitando get-historical-data" do
    ticker = 'AAPL'
    data = Date.new(2022,2,15)
    json_response = { "prices" => [{ "date" => data.to_time.to_i, "close" => 172.7899932861328 }] }

    Utils.stub(:fetch_rapidapi_json, json_response) do
      preco = BuscaCotacao::BolsaYfinance.busca(ticker, data)
      assert_equal 172.7899932861328, preco
    end
  end

end
