require 'test_helper'

class ProventoPolicyTest < ActiveSupport::TestCase
  setup do
    @admin = users :admin
    @example_investor = users :example_investor
    @second_investor = users :second_investor
    @provento = proventos :dividendo_itsa4
  end
  
  test 'permissões de admin' do
    assert_permit @admin, :provento, :index
    assert_permit @admin, @provento, :show
    assert_permit @admin, @provento, :new
    assert_permit @admin, @provento, :create
    assert_permit @admin, @provento, :edit
    assert_permit @admin, @provento, :update
    assert_permit @admin, @provento, :destroy
  end

  test 'permissões para dono' do
    refute_permit @example_investor, :provento, :index
    assert_permit @example_investor, @provento, :show
    assert_permit @example_investor, @provento, :new
    assert_permit @example_investor, @provento, :create
    assert_permit @example_investor, @provento, :edit
    assert_permit @example_investor, @provento, :update
    assert_permit @example_investor, @provento, :destroy
  end

  test 'permissões para NÃO dono' do
    refute_permit @second_investor, :provento, :index
    refute_permit @second_investor, @provento, :show
    refute_permit @second_investor, @provento, :new
    refute_permit @second_investor, @provento, :create
    refute_permit @second_investor, @provento, :edit
    refute_permit @second_investor, @provento, :update
    refute_permit @second_investor, @provento, :destroy
  end
end