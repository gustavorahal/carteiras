require 'application_system_test_case'

class ExtratoSystemTest < ApplicationSystemTestCase

  def setup
    @cc = conta_correntes(:vitreo_brl)
    @carteira = @cc.carteira

    sign_in users(:example_investor)
  end

  test "deleta extrato através do btn delete" do
    @entrada_cc = extratos(:one)
    visit carteira_conta_corrente_path @carteira, @cc
    assert_text @entrada_cc.descricao
    find(:xpath, "//form[@action='#{carteira_conta_corrente_extrato_path(@carteira, @cc, @entrada_cc)}']/button").click
    assert_no_text @entrada_cc.descricao
  end

  test "não mostra botão deleta extrato para entrada extrato processado" do
    @entrada_cc = extratos(:two_processado)
    visit carteira_conta_corrente_path @carteira, @cc
    assert_text @entrada_cc.descricao
    assert has_no_selector?(:xpath, "//form[@action='#{carteira_conta_corrente_extrato_path(@carteira, @cc, @entrada_cc)}']/button")
  end

end