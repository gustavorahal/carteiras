require 'application_system_test_case'

class ImportExtratosTest < ApplicationSystemTestCase
  # test 'importa extrato Vitreo' do
  #   cc = conta_correntes(:vitreo_brl)
  #   carteira = cc.carteira
  #
  #   visit carteira_conta_corrente_path carteira, cc
  #
  #   assert_selector 'h2', text: "Conta Corrente #{cc.corretora.nome} (#{cc.moeda})"
  #
  #   attach_file('Importar extrato', file_path('extrato-vitreo.xls'), make_visible: true) # arquivo de extrato bugado
  #
  #   click_on 'Importar'
  #
  #   assert_selector 'td', text: 'NOTA CORRETAGEM 123382 PREGÃO 17/03/2021'
  # end

  test 'importa extrato XP' do
    _test_importa_extrato(:xp_brl, 'extrato_xp.xlsx',
                          ['TED BCO 341 AGE 8294 CTA 44634 - RETIRADA EM C/C',
                                     'RENDIMENTOS DE CLIENTES VILG11 S/ 27',
                                     '-R$ 3.029,50'])

  end

  test 'importa extrato Avenue BRL' do
    _test_importa_extrato(:avenue_brl, 'extrato_avenue_brl.xlsx',
                                        ['Remessa de Câmbio Padrão: $3531.63',
                                                   'IOF sob remessa R$19088.82 a R$ 5.4051',
                                                   'R$ 19.161,37'])
  end

  #
  # Private
  #

  def _test_importa_extrato(cc_nome_sym, file_name, checa_textos)
    cc = conta_correntes(cc_nome_sym)
    carteira = cc.carteira

    visit carteira_conta_corrente_path carteira, cc

    assert_selector 'h2', text: "Conta Corrente #{cc.corretora.nome} (#{cc.moeda})"

    attach_file('Importar extrato', file_path(file_name), make_visible: true)

    click_on 'Importar'

    checa_textos.each do |texto|
      assert_selector 'td', text: texto
    end
  end

end