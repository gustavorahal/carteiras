require 'test_helper'

class OperacaoPolicyTest < ActiveSupport::TestCase
  setup do
    @admin = users :admin
    @example_investor = users :example_investor
    @second_investor = users :second_investor
    @operacao = operacoes :gndi3_op1
  end
  
  test 'permissões de admin' do
    assert_permit @admin, :operacao, :index
    assert_permit @admin, @operacao, :show
    assert_permit @admin, @operacao, :new
    assert_permit @admin, @operacao, :create
    assert_permit @admin, @operacao, :edit
    assert_permit @admin, @operacao, :update
    assert_permit @admin, @operacao, :destroy
  end

  test 'permissões para dono' do
    refute_permit @example_investor, :operacao, :index
    assert_permit @example_investor, @operacao, :show
    assert_permit @example_investor, @operacao, :new
    assert_permit @example_investor, @operacao, :create
    assert_permit @example_investor, @operacao, :edit
    assert_permit @example_investor, @operacao, :update
    assert_permit @example_investor, @operacao, :destroy
  end

  test 'permissões para NÃO dono' do
    refute_permit @second_investor, :operacao, :index
    refute_permit @second_investor, @operacao, :show
    refute_permit @second_investor, @operacao, :new
    refute_permit @second_investor, @operacao, :create
    refute_permit @second_investor, @operacao, :edit
    refute_permit @second_investor, @operacao, :update
    refute_permit @second_investor, @operacao, :destroy
  end
end