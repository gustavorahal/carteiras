require 'test_helper'

class BuscaTesouroTest < ActiveSupport::TestCase
  test "busca LFT 2027" do
    nome_titulo_app = 'Tesouro Selic 2027'
    data = Date.new(2021,3,18)

    dados = BuscaCotacao::Tesouro.busca(nome_titulo_app, data)

    # Dados buscados na planilha
    # 18/03/2021	0,35%	0,36%	10.583,62	10.577,38	10.576,09
    assert_equal 10576.09, dados[data]
  end

  test "busca Tesouro IPCA+ 2035" do
    nome_titulo_app = 'Tesouro IPCA+ 2035'
    data = Date.new(2022,1,11)

    dados = BuscaCotacao::Tesouro.busca(nome_titulo_app, data)

    # Dados buscados na planilha
    # 11/01/2022	5.65%	5.77%	1,824.56	1,796.42	1,796.42
    assert_equal 1796.42, dados[data]
  end

  test "busca Titulo nao existe" do
    nome_titulo_app = 'Titulo nao existe'
    data = Date.new(2022,1,11)

    dados = BuscaCotacao::Tesouro.busca(nome_titulo_app, data)

    assert_nil dados
  end

  test "busca Tesouro IPCA+ 2035 data invalida" do
    nome_titulo_app = 'Tesouro IPCA+ 2035'
    data = Date.today + 5

    dados = BuscaCotacao::Tesouro.busca(nome_titulo_app, data)

    assert_nil dados
  end
end