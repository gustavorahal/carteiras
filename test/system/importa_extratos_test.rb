require 'application_system_test_case'

class ImportaExtratosTest < ApplicationSystemTestCase
  setup do
    skip "Os fixtures privados de extratos de corretoras foram removidos do repositorio publico."
  end

  test 'importa extrato Vitreo' do
    _test_importa_extrato(:vitreo_brl, 'extrato_vitreo.xslx',
                          ['Pagamento de Frações CSAN3',
                           'TED BCO 341 AGE 8294 CTA 04463 4 - CREDITO EM C/C',
                           '-R$ 24.745,41', 'R$ 25.598,52'], ["* PROV * Pagamento de Rendimentos RBRR11"])
  end

  test 'importa extrato XP' do
    _test_importa_extrato(:xp_brl, 'extrato_xp.xlsx',
                          ['TED BCO 341 AGE 8294 CTA 44634 - RETIRADA EM C/C',
                           'RENDIMENTOS DE CLIENTES VILG11 S/ 27',
                           '-R$ 3.029,50', 'R$ 56,04'])

  end

  test 'importa extrato Avenue BRL' do
    _test_importa_extrato(:avenue_brl, 'extrato_avenue_brl.xlsx',
                          ['Remessa de Câmbio Padrão: $3531.63',
                           'IOF sob remessa R$19088.82 a R$ 5.4051',
                           'R$ 19.161,37', 'R$ 72,55'])
  end

  test 'importa extrato Avenue USD' do
    _test_importa_extrato(:avenue_usd, 'extrato_avenue_usd.xlsx',
                          ['Câmbio Padrão : R$24905.36',
                           'Compra de 0.74 BRK.B a $ 250.98',
                           'US$ 4.455,56', 'US$ 3.516,89'])
  end

  #
  # Private
  #

  def _test_importa_extrato(cc_nome_sym, file_name, checa_textos, nao_textos = [])
    cc = conta_correntes(cc_nome_sym)
    carteira = cc.carteira

    sign_in users(:example_investor)

    visit carteira_conta_corrente_path carteira, cc

    assert_selector 'h2', text: "Conta Corrente #{cc.corretora.nome} (#{cc.moeda})"

    attach_file('Importar extrato', file_path(file_name), make_visible: true)

    click_on 'Importar'

    checa_textos.each do |texto|
      assert_selector 'td', text: texto
    end
    nao_textos.each do |texto|
      assert_selector 'td', { count: 0, text: texto }
    end
  end

end
