require 'test_helper'

class ImportaTest < ActiveSupport::TestCase
  setup do
    skip "Os fixtures privados de extratos de corretoras foram removidos do repositorio publico."
  end

  test "importa extrato avenue BRL" do
    cc = conta_correntes :avenue_brl
    Extratos::Importa.importar cc, file_path('extrato_avenue_brl.csv')

    assert cc.saldo(Date.today) == 0.00
  end

  test 'importa extrato avenue USD' do
    cc = conta_correntes :avenue_usd
    Extratos::Importa.importar cc, file_path('extrato_avenue_usd.csv')

    assert cc.saldo(Date.today) == 0.00
  end

  test 'importa extrato XP' do
    cc = conta_correntes :xp_brl
    Extratos::Importa.importar cc, file_path('extrato_xp.xlsx')

    assert Extrato.find_by(conta_corrente: cc, descricao: 'DEBITO REF.TAXA DE REMUNERAÇÃO-BTC BRIVVBCTF001', valor: -226.51).present?
    assert Extrato.find_by(conta_corrente: cc, descricao: 'RENDIMENTOS DE CLIENTES HGCR11 S/            190', valor: 228.00).present?
  end

  test 'importa extrato Vitreo' do
    cc = conta_correntes :vitreo_brl
    Extratos::Importa.importar cc, file_path('extrato_vitreo.xlsx')

    assert Extrato.find_by(conta_corrente: cc,
                           movimentacao: "2021-08-24",
                           liquidacao: "2021-08-26",
                           descricao: 'NOTA CORRETAGEM 246537 PREGÃO 24/08/2021',
                           valor: 186.41).present?

    assert_empty Extrato.where(conta_corrente: cc, descricao: '* PROV * Pagamento de Rendimentos RBRR11')
    assert Extrato.where(conta_corrente: cc, descricao: 'Pagamento de Rendimentos RBRR11').present?
  end
end
