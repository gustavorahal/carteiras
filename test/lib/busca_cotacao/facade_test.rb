require 'test_helper'

class FacadeTest < ActiveSupport::TestCase
  test "busca LFT 2027" do
    titulo = 'Tesouro Selic 2027'
    data = Date.new(2021,3,18)

    BuscaCotacao::Tesouro.stub(:busca, { data => 10576.09 }) do
      resultado = BuscaCotacao::Facade.tesouro(titulo, data)

      assert_equal 10576.09, resultado.preco
      assert_equal data, resultado.data
      assert_equal 'tesouro_gov', resultado.fonte
      assert_equal titulo, resultado.nome
    end
  end

  test "busca titulo que não existe" do
    titulo = 'Tesouro ao fim do arco iris'
    data = Date.new(2021,3,18)
    BuscaCotacao::Tesouro.stub(:busca, nil) do
      resultado = BuscaCotacao::Facade.tesouro(titulo, data)
      assert_nil resultado
    end
  end

  test "busca titulo em data invalida (ou que não existe)" do
    titulo = 'Tesouro Selic 2027'
    data = Date.today + 10.days
    BuscaCotacao::Tesouro.stub(:busca, nil) do
      resultado = BuscaCotacao::Facade.tesouro(titulo, data)
      assert_nil resultado
    end
  end

  test 'busca ação brasileira (ITSA4) em data válida' do
    data = Date.new(2021,4,13)
    ativo = ativos(:itsa4)
    BuscaCotacao::Bolsa.stub(:busca, [10.0, "marketstack"]) do
      resultado = BuscaCotacao::Facade.bolsa(ativo.nome, ativo.moeda_negociacao, data)

      assert_kind_of BigDecimal, resultado.preco
      assert_equal data, resultado.data
      assert_equal ativo.nome, resultado.nome
    end
  end

  test 'busca ação americana (DIS) em data válida' do
    data = Date.new(2021,4,13)
    ativo = ativos(:dis)
    BuscaCotacao::Bolsa.stub(:busca, [185.49, "yahoo_finance_rapidapi"]) do
      resultado = BuscaCotacao::Facade.bolsa(ativo.nome, ativo.moeda_negociacao, data)

      assert_equal 185.49, resultado.preco
      assert_equal data, resultado.data
      assert_equal ativo.nome, resultado.nome
    end
  end

  test 'busca ação ITSA4 em data INválida' do
    data = Date.today + 10.days
    ativo = ativos(:itsa4)
    BuscaCotacao::Bolsa.stub(:busca, [nil, "marketstack"]) do
      resultado = BuscaCotacao::Facade.bolsa(ativo.nome, ativo.moeda_negociacao, data)

      assert_nil resultado
    end
  end

  test 'busca ação que não existe' do
    data = Date.new(2021,4,13)
    ticker = 'NAOEXISTESA'
    BuscaCotacao::Bolsa.stub(:busca, [nil, "marketstack"]) do
      resultado = BuscaCotacao::Facade.bolsa(ticker, 'BRL', data)

      assert_nil resultado
    end
  end

  test 'busca fundo que existe' do
    data = Date.new(2021,4,13)
    cnpj = ativos(:fundo_dolar).cnpj
    BuscaCotacao::Fundo.stub(:busca, 1.13568224) do
      resultado = BuscaCotacao::Facade.fundo(cnpj, data)

      assert_equal 1.13568224, resultado.preco
      assert_equal data, resultado.data
      assert_equal cnpj, resultado.nome
      assert_equal 'cvm_gov', resultado.fonte
    end
  end

  test 'busca fundo que NÃO existe' do
    data = Date.new(2021,4,13)
    cnpj = '111111111'
    BuscaCotacao::Fundo.stub(:busca, nil) do
      resultado = BuscaCotacao::Facade.fundo(cnpj, data)

      assert_nil resultado
    end
  end

  test 'busca moeda USDBRL' do
    data = Date.new(2021,4,19)
    BuscaCotacao::Moeda.stub(:busca, [5.5744, "bcb_gov"]) do
      resultado = BuscaCotacao::Facade.moeda('USDBRL', data)

      assert_kind_of BigDecimal, resultado.preco
      assert_equal 5.5744, resultado.preco
      assert_equal "bcb_gov", resultado.fonte
      assert_equal data, resultado.data
    end
  end

  test 'busca moeda USDBRL em data sem cotacao' do
    data = Date.new(2021,4,17)
    BuscaCotacao::Moeda.stub(:busca, nil) do
      resultado = BuscaCotacao::Facade.moeda('USDBRL', data)

      assert_nil resultado
    end
  end

end
