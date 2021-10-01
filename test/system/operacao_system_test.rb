require 'application_system_test_case'

class OperacaoSystemTest < ApplicationSystemTestCase
  def setup
    @cc = conta_correntes(:vitreo_brl)
    @carteira = @cc.carteira
    @corretora = @cc.corretora
    @ativo = ativos(:bpan4)

    sign_in users(:example_investor)
  end

  test 'nova operação especificando valor e valor_unit sem quantidade' do
    valor = 110
    valor_unit = 11
    quant = valor/valor_unit

    visit new_carteira_operacao_path @carteira

    select @ativo.nome, from: "Ativo"
    select @corretora.nome, from: "Corretora"
    select "C", from: "Operacao"
    fill_in "Valor unit", with: valor_unit
    fill_in "Valor", with: valor

    click_on "Salvar"

    assert Operacao.find_by(ativo: @ativo, quantidade: quant, valor_unit: valor_unit, corretora: @corretora)
    assert_text "Operação criada com sucesso!"
  end

  test 'nova operação especificando valor e quantidade sem valor_unit' do
    valor = 110
    quant = 11
    valor_unit = valor/quant

    visit new_carteira_operacao_path @carteira

    select @ativo.nome, from: "Ativo"
    select @corretora.nome, from: "Corretora"
    select "C", from: "Operacao"
    fill_in "Quantidade", with: quant
    fill_in "Valor", with: valor

    click_on "Salvar"

    assert Operacao.find_by(ativo: @ativo, quantidade: quant, valor_unit: valor_unit, corretora: @corretora)
    assert_text "Operação criada com sucesso!"
  end

  test 'nova operação sem especificar quantidade nem valor_unit' do
    valor = 110
    quant = 11
    valor_unit = valor/quant

    visit new_carteira_operacao_path @carteira

    select @ativo.nome, from: "Ativo"
    select @corretora.nome, from: "Corretora"
    select "C", from: "Operacao"
    fill_in "Valor", with: valor

    click_on "Salvar"

    assert_text "Quantidade OU valor unitario precisam ser especificados"
  end

  test 'nova operação especificando quantidade e valor_unit, sem valor total' do
    valor = nil
    quant = 11
    valor_unit = 10

    visit new_carteira_operacao_path @carteira

    select @ativo.nome, from: "Ativo"
    select @corretora.nome, from: "Corretora"
    select "C", from: "Operacao"
    fill_in "Quantidade", with: quant
    fill_in "Valor unit", with: valor_unit

    click_on "Salvar"

    assert_text "Operação criada com sucesso!"
  end

end