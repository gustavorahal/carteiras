require 'test_helper'

class ProcessaAporteTest < ActiveSupport::TestCase
  test "avenue: processa aporte" do
    _test_processa_aporte :avenue_brl, file_path('extrato_avenue_brl.xlsx'), 19_161.37
  end

  test "vitreo: processa aporte" do
    _test_processa_aporte :vitreo_brl, file_path('extrato_vitreo.csv'), 110_000.00
  end

  test "xp: processa aporte" do
    _test_processa_aporte :xp_brl, file_path('extrato_xp.xlsx'), 66_000.00
  end


  #
  # Private
  #

  def _test_processa_aporte(cc_symbol, arquivo_import, valor)
    cc = conta_correntes cc_symbol
    Extratos::Importa.importar cc, arquivo_import
    Extratos::Processa.processar cc

    assert Movimentacao.find_by(carteira: cc.carteira,
                                corretora: cc.corretora,
                                valor: valor).present?
  end

end
