require 'test_helper'

class ProcessaResgateTest < ActiveSupport::TestCase
  test "avenue: processa resgate da conta BRL" do
    _test_processa_retirada :avenue_brl, file_path('extrato_avenue_brl.csv'), Date.new(2021,9,14),-15804.73
  end

  test "avenue: processa transferencia da conta inventimento para banking" do
    _test_processa_retirada :avenue_usd, file_path('extrato_avenue_usd.csv'), Date.new(2021,11,2), -14.69
  end

  #
  # Private
  #

  def _test_processa_retirada(cc_symbol, arquivo_import, data, valor)
    cc = conta_correntes cc_symbol
    Extratos::Importa.importar cc, arquivo_import
    Extratos::Processa.processar cc

    assert Movimentacao.find_by(carteira: cc.carteira,
                                corretora: cc.corretora,
                                data: data,
                                valor: valor).present?
  end

end