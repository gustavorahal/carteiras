require 'test_helper'

class AuthorizationTest < ActionDispatch::IntegrationTest
  setup do
    @carteira = carteiras :example_growth
    @conta_corrente = conta_correntes :vitreo_brl
    @operacao = operacoes :gndi3_op1
    @second_investor = users :second_investor
  end

  test 'não permite acessar conta corrente de outro investidor' do
    sign_in @second_investor

    assert_raises(ActiveRecord::RecordNotFound) do
      get carteira_conta_corrente_path(@carteira, @conta_corrente)
    end
  end

  test 'não permite editar operação de outro investidor' do
    sign_in @second_investor

    assert_raises(ActiveRecord::RecordNotFound) do
      get edit_carteira_operacao_path(@carteira, @operacao)
    end
  end

  test 'não permite acessar referências diretamente como investidor' do
    sign_in @second_investor

    assert_raises(Pundit::NotAuthorizedError) do
      get referencias_path
    end
  end
end
