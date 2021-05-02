require 'test_helper'

class CarteiraPolicyTest < ActiveSupport::TestCase
  setup do
    @admin = users :admin
    @example_investor = users :example_investor
    @second_investor = users :second_investor
    @carteira = carteiras :example_growth
  end
  
  test 'permissões de admin' do
    assert_permit @admin, :carteira, :index
    assert_permit @admin, @carteira, :show
    assert_permit @admin, @carteira, :new
    assert_permit @admin, @carteira, :create
    assert_permit @admin, @carteira, :edit
    assert_permit @admin, @carteira, :update
    assert_permit @admin, @carteira, :destroy
  end

  test 'permissões para dono' do
    refute_permit @example_investor, :carteira, :index
    assert_permit @example_investor, @carteira, :show
    assert_permit @example_investor, @carteira, :new
    assert_permit @example_investor, @carteira, :create
    assert_permit @example_investor, @carteira, :edit
    assert_permit @example_investor, @carteira, :update
    assert_permit @example_investor, @carteira, :destroy
  end

  test 'permissões para NÃO dono' do
    refute_permit @second_investor, :carteira, :index
    refute_permit @second_investor, @carteira, :show
    refute_permit @second_investor, @carteira, :new
    refute_permit @second_investor, @carteira, :create
    refute_permit @second_investor, @carteira, :edit
    refute_permit @second_investor, @carteira, :update
    refute_permit @second_investor, @carteira, :destroy
  end
end