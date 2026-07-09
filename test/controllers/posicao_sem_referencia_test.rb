require 'test_helper'

class PosicaoSemReferenciaTest < ActionDispatch::IntegrationTest
  setup do
    @carteira = carteiras(:example_growth)
    @carteira.update_column(:referencia_id, nil)

    sign_in users(:example_investor)
  end

  test 'posicao renderiza quando carteira nao tem referencia' do
    get posicao_path(@carteira)

    assert_response :success
    assert_select 'a', text: /Atual vs. Referência/, count: 0
    assert_select 'td', text: 'Referência', count: 0
  end

  test 'atual vs referencia volta para book quando carteira nao tem referencia' do
    get posicao_path(@carteira, view: 'atual_vs_ref')

    assert_response :success
    assert_select '.alert', text: /Carteira sem referência/
  end
end
