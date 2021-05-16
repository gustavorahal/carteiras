require 'test_helper'

class BuscaFundoTest < ActiveSupport::TestCase
  test "busca fundo Vitreo Dolar" do
    cnpj = ativos(:fundo_dolar).cnpj

    valor_cota = BuscaCotacao::Fundo.busca(cnpj, Date.new(2021,4,19))
    assert_equal 1.10770676, valor_cota

    valor_cota = BuscaCotacao::Fundo.busca(cnpj, Date.new(2021,3,1))
    assert_equal 1.11714613, valor_cota
  end
end