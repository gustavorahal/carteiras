require 'test_helper'

class BuscaMoedaTest < ActiveSupport::TestCase
  test "busca USDBRL em data válida" do
    response = { "value" => [{ "cotacaoCompra" => 5.5744 }] }.to_json

    Net::HTTP.stub(:get, response) do
      resultado = BuscaCotacao::Moeda.busca('USDBRL', Date.new(2021,4,19))
      assert_equal [5.5744, "bcb_gov"], resultado
    end
  end

  test "busca USDBRL em data INválida" do
    response = { "value" => [] }.to_json

    Net::HTTP.stub(:get, response) do
      resultado = BuscaCotacao::Moeda.busca('USDBRL', Date.new(2021,4,17))
      assert_nil resultado
    end
  end

  test "busca cotacao moeda que não existe" do
    assert_raises RuntimeError do
      BuscaCotacao::Moeda.busca('NAOEXISTE', Date.new(2021,4,19))
    end
  end

  test "busca BTCBRL em data válida" do
    json_response = { "bitcoin" => { "brl" => 300_000.0 } }

    Utils.stub(:fetch_rapidapi_json, json_response) do
      resultado = BuscaCotacao::Moeda.busca('BTCBRL', Date.new(2021,4,19))
      assert_equal [300_000.0, 'coingecko_rapidapi'], resultado
    end
  end

end
