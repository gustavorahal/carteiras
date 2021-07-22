require 'test_helper'

class ImportaTest < ActiveSupport::TestCase
  test "importa extrato avenue BRL" do
    cc = conta_correntes :avenue_brl
    Extratos::Importa.importar cc, file_path('extrato_avenue_brl.xlsx')

    assert Extrato.find_by(conta_corrente: cc, descricao: 'Remessa de Câmbio Padrão: $3531.63', valor: -19_088.82).present?
    assert Extrato.find_by(conta_corrente: cc, descricao: 'IOF sob remessa R$19088.82 a R$ 5.4051', valor: -72.54).present?
  end

  test 'importa extrato avenue USD' do
    cc = conta_correntes :avenue_usd
    Extratos::Importa.importar cc, file_path('extrato_avenue_usd.xlsx')

    assert Extrato.find_by(conta_corrente: cc, descricao: 'Câmbio Padrão : R$24905.36', valor: 4450.01).present?
    assert Extrato.find_by(conta_corrente: cc, descricao: 'Compra de 0.74 BRK.B a $ 250.98', valor: -185.73).present?
  end

  test 'importa extrato XP' do
    cc = conta_correntes :xp_brl
    Extratos::Importa.importar cc, file_path('extrato_xp.xlsx')

    assert Extrato.find_by(conta_corrente: cc, descricao: 'TED BCO 341 AGE 8294 CTA 44634 - RETIRADA EM C/C', valor: -3029.50).present?
    assert Extrato.find_by(conta_corrente: cc, descricao: 'RENDIMENTOS DE CLIENTES VILG11 S/ 27', valor: 16.20).present?
  end

  test 'importa extrato Vitreo' do
    cc = conta_correntes :vitreo_brl
    Extratos::Importa.importar cc, file_path('extrato_vitreo.xlsx')

    assert Extrato.find_by(conta_corrente: cc, descricao: 'Pagamento de Frações  CSAN3', valor: 7.68).present?
    assert Extrato.find_by(conta_corrente: cc, descricao: 'TED BCO 341 AGE 8294  CTA 04463 4  - CREDITO EM C/C', valor: 3029.50).present?

    assert_empty Extrato.where(conta_corrente: cc, descricao: '* PROV * Pagamento de Rendimentos RBRR11')
    assert Extrato.where(conta_corrente: cc, descricao: 'Pagamento de Rendimentos RBRR11').present?
  end
end
