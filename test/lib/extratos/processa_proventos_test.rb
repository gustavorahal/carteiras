require 'test_helper'

class ProcessaProventosTest < ActiveSupport::TestCase
  test "vitreo: processa dividendo" do
    _test_processa_proventos :vitreo_brl,
                             file_path('extrato_vitreo.csv'),
                             342.59, 'dividendo', ativos(:vale3)
  end

  test "vitreo: processa JCP" do
    _test_processa_proventos :vitreo_brl,
                             file_path('extrato_vitreo.csv'),
                             71.04, 'jcp', ativos(:vale3)
  end

  test "vitreo: processa rendimentos FII" do
    _test_processa_proventos :vitreo_brl,
                             file_path('extrato_vitreo.csv'),
                             7.20, 'rendimento', ativos(:rbrf11)
  end

  test "xp: processa dividendo" do
    _test_processa_proventos :xp_brl,
                             file_path('extrato_xp.xlsx'),
                             8.04, 'dividendo', ativos(:itsa4)

  end

  test "xp: processa JCP" do
    _test_processa_proventos :xp_brl,
                             file_path('extrato_xp.xlsx'),
                             0.04, 'jcp', ativos(:itsa4)

  end

  test "xp: processa rendimentos FII" do
    _test_processa_proventos :xp_brl,
                             file_path('extrato_xp.xlsx'),
                             9.00, 'rendimento', ativos(:rbrf11)
  end

  #
  # Private
  #

  def _test_processa_proventos(cc_symbol, arquivo_import, valor, evento, ativo)
    cc = conta_correntes cc_symbol
    Extratos::Importa.importar cc, arquivo_import
    Extratos::Processa.processar cc

    assert Provento.find_by(carteira: cc.carteira,
                            corretora: cc.corretora,
                            ativo: ativo,
                            evento: evento,
                            valor_liquido: valor).present?
  end
end
