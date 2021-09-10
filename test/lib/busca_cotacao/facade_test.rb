require 'test_helper'

class FacadeTest < ActiveSupport::TestCase
  test "busca LFT 2027" do
    titulo = 'Tesouro Selic 2027'
    data = Date.new(2021,3,18)
    resultado = BuscaCotacao::Facade.tesouro(titulo, data)

    # Dados buscados na planilha
    # 18/03/2021	0,35%	0,36%	10.583,62	10.577,38	10.576,09
    assert_equal 10576.09, resultado.preco
    assert_equal data, resultado.data
    assert_equal 'tesouro_gov', resultado.fonte
    assert_equal titulo, resultado.nome
  end

  test "busca titulo que não existe" do
    titulo = 'Tesouro ao fim do arco iris'
    data = Date.new(2021,3,18)
    resultado = BuscaCotacao::Facade.tesouro(titulo, data)

    assert_nil resultado
  end

  test "busca titulo em data invalida (ou que não existe)" do
    titulo = 'Tesouro Selic 2027'
    data = Date.today + 10.days
    resultado = BuscaCotacao::Facade.tesouro(titulo, data)

    assert_nil resultado
  end

  test 'busca ação brasileira (ITSA4) em data válida' do
    data = Date.new(2021,4,13)
    ativo = ativos(:itsa4)
    resultado = BuscaCotacao::Facade.bolsa(ativo.nome, ativo.moeda_negociacao, data)

    assert_equal 10.19, resultado.preco
    assert_equal data, resultado.data
    assert_equal ativo.nome, resultado.nome
  end

  test 'busca ação americana (DIS) em data válida' do
    data = Date.new(2021,4,13)
    ativo = ativos(:dis)
    resultado = BuscaCotacao::Facade.bolsa(ativo.nome, ativo.moeda_negociacao, data)

    assert_equal 185.49, resultado.preco
    assert_equal data, resultado.data
    assert_equal ativo.nome, resultado.nome
  end

  test 'busca ação ITSA4 em data INválida' do
    data = Date.today + 10.days
    ativo = ativos(:itsa4)
    resultado = BuscaCotacao::Facade.bolsa(ativo.nome, ativo.moeda_negociacao, data)

    assert_nil resultado
  end

  test 'busca ação que não existe' do
    data = Date.new(2021,4,13)
    ticker = 'NAOEXISTESA'
    resultado = BuscaCotacao::Facade.bolsa(ticker, 'BRL', data)

    assert_nil resultado
  end

  test 'busca fundo que existe' do
    data = Date.new(2021,4,13)
    cnpj = ativos(:fundo_dolar).cnpj
    resultado = BuscaCotacao::Facade.fundo(cnpj, data)

    assert_equal 1.13568224, resultado.preco
    assert_equal data, resultado.data
    assert_equal cnpj, resultado.nome
    assert_equal 'cvm_gov', resultado.fonte
  end

  test 'busca fundo que NÃO existe' do
    data = Date.new(2021,4,13)
    cnpj = '111111111'
    resultado = BuscaCotacao::Facade.fundo(cnpj, data)

    assert_nil resultado
  end

  test 'busca moeda USDBRL' do
    data = Date.new(2021,4,19)
    resultado = BuscaCotacao::Facade.moeda('USDBRL', data)

    assert_equal 5.5744, resultado.preco
    assert_equal "bcb_gov", resultado.fonte
    assert_equal data, resultado.data
  end

  test 'busca moeda USDBRL em data sem cotacao' do
    data = Date.new(2021,4,17)
    resultado = BuscaCotacao::Facade.moeda('USDBRL', data)

    assert_nil resultado
  end

end