require 'test_helper'

class FacadeTest < ActiveSupport::TestCase
  test "busca LFT 2027" do
    titulo = 'Tesouro Selic 2027'
    data = Date.new(2021,3,18)
    resultado = BuscaCotacao::Facade.tesouro(titulo, data)

    # Dados buscados na planilha
    # 18/03/2021	0,35%	0,36%	10.583,62	10.577,38	10.576,09
    assert resultado.preco, 10577.38
    assert resultado.data, data
    assert resultado.fonte, 'tesouro_gov'
    assert resultado.nome, titulo
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
    resultado = BuscaCotacao::Facade.bolsa(ativo.nome, ativo.moeda, data)

    assert resultado.preco, 10.19
    assert resultado.data, data
    assert resultado.nome, ativo.nome
  end

  test 'busca ação americana (DIS) em data válida' do
    data = Date.new(2021,4,13)
    ativo = ativos(:dis)
    resultado = BuscaCotacao::Facade.bolsa(ativo.nome, ativo.moeda, data)

    assert resultado.preco, 185.49
    assert resultado.data, data
    assert resultado.nome, ativo.nome
  end

  test 'busca ação ITSA4 em data INválida' do
    data = Date.today + 10.days
    ativo = ativos(:itsa4)
    resultado = BuscaCotacao::Facade.bolsa(ativo.nome, ativo.moeda, data)

    assert_nil resultado
  end

  test 'busca ação que não existe' do
    data = Date.new(2021,4,13)
    ticker = 'NAOEXISTESA'
    resultado = BuscaCotacao::Facade.bolsa(ticker, 'BRL', data)

    assert_nil resultado
  end

end