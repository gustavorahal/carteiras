require 'test_helper'

class ReferenciaPolicyTest < ActiveSupport::TestCase
  setup do
    @admin = users :admin
    @example_investor = users :example_investor
    @referencia = referencia :empiricus
  end

  test 'permissões de admin' do
    assert_permit @admin, @referencia, :index
    assert_permit @admin, @referencia, :show
  end

  test 'investidor não acessa referências diretamente' do
    refute_permit @example_investor, @referencia, :index
    refute_permit @example_investor, @referencia, :show
  end

  test 'scope de referência é admin-only' do
    assert_equal [@referencia], Pundit.policy_scope!(@admin, Referencia).to_a
    assert_empty Pundit.policy_scope!(@example_investor, Referencia)
  end
end
