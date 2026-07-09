require 'test_helper'

class BuscaBolsaTest < ActiveSupport::TestCase

  test 'busca cotacao APPL hoje' do
    BuscaCotacao::BolsaMarketstack.stub(:busca, 180.0) do
      preco = BuscaCotacao::Bolsa.busca("AAPL", nil, Date.today)
      assert_equal [180.0, "marketstack"], preco
    end
  end

  test 'busca cotacao APPL em data passada' do
    BuscaCotacao::BolsaMarketstack.stub(:busca, nil) do
      BuscaCotacao::BolsaYfinance.stub(:busca, 172.79) do
        preco = BuscaCotacao::Bolsa.busca("AAPL", nil, Date.new(2022,2,15))
        assert_equal [172.79, "yahoo_finance_rapidapi"], preco
      end
    end
  end

end
