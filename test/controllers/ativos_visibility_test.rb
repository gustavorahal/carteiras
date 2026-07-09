require 'test_helper'

class AtivosVisibilityTest < ActionDispatch::IntegrationTest
  test 'investidor nao ve acoes administrativas na lista de ativos' do
    sign_in users(:example_investor)

    get ativos_path

    assert_response :success
    assert_select 'a', text: /Novo Ativo/, count: 0
    assert_select 'a', text: /Editar/, count: 0
  end

  test 'admin ve acoes administrativas na lista de ativos' do
    sign_in users(:admin)

    get ativos_path

    assert_response :success
    assert_select 'a', text: /Novo Ativo/, count: 1
    assert_select 'a', text: /Editar/, minimum: 1
  end
end
