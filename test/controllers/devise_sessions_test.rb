require "test_helper"

class DeviseSessionsTest < ActionDispatch::IntegrationTest
  test "login page renders when the dollar quote asset is missing" do
    ativo = Ativo.find_by!(nome: "USDBRL")
    Cotacao.where(ativo: ativo).delete_all
    ativo.delete

    get new_user_session_path

    assert_response :success
    assert_select "span.navbar-text", count: 0
  end
end
