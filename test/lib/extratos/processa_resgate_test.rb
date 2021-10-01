require 'test_helper'

class ProcessaResgateTest < ActiveSupport::TestCase
  test "avenue: processa resgate" do
    _test_processa_retirada :avenue_brl, file_path('extrato_avenue_brl.csv'), -61664.75
  end


  #
  # Private
  #

  def _test_processa_retirada(cc_symbol, arquivo_import, valor)
    cc = conta_correntes cc_symbol
    Extratos::Importa.importar cc, arquivo_import
    Extratos::Processa.processar cc

    assert Movimentacao.find_by(carteira: cc.carteira,
                                corretora: cc.corretora,
                                valor: valor).present?
  end

end