require 'test_helper'

class BuscaFundoTest < ActiveSupport::TestCase

  test "busca arquivo CVM" do
    num_ano = 2022
    num_mes = 9
    assert_equal "inf_diario_fi_202209.csv", BuscaCotacao::Fundo._busca_arquivo_cvm(num_ano, num_mes)
    assert File.exist? "inf_diario_fi_202209.csv"
  end

  test "busca fundo Vitreo Dolar" do
    cnpj = ativos(:fundo_dolar).cnpj

    valor_cota = BuscaCotacao::Fundo.busca(cnpj, Date.new(2021,4,19))
    assert_equal 1.10770676, valor_cota

    valor_cota = BuscaCotacao::Fundo.busca(cnpj, Date.new(2021,3,1))
    assert_equal 1.11714613, valor_cota
  end
end