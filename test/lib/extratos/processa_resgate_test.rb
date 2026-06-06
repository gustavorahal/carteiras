require 'test_helper'

class ProcessaResgateTest < ActiveSupport::TestCase
  setup do
    skip "Os fixtures privados de extratos de corretoras foram removidos do repositorio publico."
  end

  test "avenue: processa resgate da conta BRL" do
    _test_retirada :avenue_brl, file_path('extrato_avenue_brl.csv'), Date.new(2020,9,14),-20000
  end

  test "avenue: processa transferencia da conta inventimento para banking" do
    _test_retirada :avenue_usd, file_path('extrato_avenue_usd.csv'), Date.new(2021,11,2), -14.69
    # testa se nao estamos processando mais do que deveriamos (greedy match)
    _test_retirada :avenue_usd, file_path('extrato_avenue_usd.csv'), Date.new(2021,8,13), 3.10, false
  end

  #
  # Private
  #

  def _test_retirada(cc_symbol, arquivo_import, data, valor, match = true)
    cc = conta_correntes cc_symbol
    Extratos::Importa.importar cc, arquivo_import
    Extratos::Processa.processar cc

    result = Movimentacao.find_by(carteira: cc.carteira,
                                  corretora: cc.corretora,
                                  data: data,
                                  valor: valor).present?
    if match
      assert result.present?
    else
      assert result.blank?
    end
  end

end
