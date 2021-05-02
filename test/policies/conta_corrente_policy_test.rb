require 'test_helper'

class ContaCorrentePolicyTest < ActiveSupport::TestCase
  setup do
    @admin = users :admin
    @example_investor = users :example_investor
    @second_investor = users :second_investor
    @conta_corrente = conta_correntes :vitreo_brl
  end
  
  test 'permissões de admin' do
    assert_permit @admin, :conta_corrente, :index
    assert_permit @admin, @conta_corrente, :show
    assert_permit @admin, @conta_corrente, :new
    assert_permit @admin, @conta_corrente, :create
    assert_permit @admin, @conta_corrente, :edit
    assert_permit @admin, @conta_corrente, :update
    assert_permit @admin, @conta_corrente, :destroy
  end

  test 'permissões para dono' do
    refute_permit @example_investor, :conta_corrente, :index
    assert_permit @example_investor, @conta_corrente, :show
    assert_permit @example_investor, @conta_corrente, :new
    assert_permit @example_investor, @conta_corrente, :create
    assert_permit @example_investor, @conta_corrente, :edit
    assert_permit @example_investor, @conta_corrente, :update
    assert_permit @example_investor, @conta_corrente, :destroy
  end

  test 'permissões para NÃO dono' do
    refute_permit @second_investor, :conta_corrente, :index
    refute_permit @second_investor, @conta_corrente, :show
    refute_permit @second_investor, @conta_corrente, :new
    refute_permit @second_investor, @conta_corrente, :create
    refute_permit @second_investor, @conta_corrente, :edit
    refute_permit @second_investor, @conta_corrente, :update
    refute_permit @second_investor, @conta_corrente, :destroy
  end
end