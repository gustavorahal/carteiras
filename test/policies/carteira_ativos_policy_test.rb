require 'test_helper'

class CarteiraAtivosPolicyTest < ActiveSupport::TestCase
  setup do
    @admin = users :admin
    @example_investor = users :example_investor
    @second_investor = users :second_investor
    @carteira_ativos = CarteiraAtivos.new(carteiras(:example_growth), Date.today)
  end
  
  test 'permissões de admin' do
    assert_permit @admin, :carteira_ativos, :index
    assert_permit @admin, @carteira_ativos, :show
    assert_permit @admin, @carteira_ativos, :new
    assert_permit @admin, @carteira_ativos, :create
    assert_permit @admin, @carteira_ativos, :edit
    assert_permit @admin, @carteira_ativos, :update
    assert_permit @admin, @carteira_ativos, :destroy
  end

  test 'permissões para dono' do
    refute_permit @example_investor, :carteira_ativos, :index
    assert_permit @example_investor, @carteira_ativos, :show
    assert_permit @example_investor, @carteira_ativos, :new
    assert_permit @example_investor, @carteira_ativos, :create
    assert_permit @example_investor, @carteira_ativos, :edit
    assert_permit @example_investor, @carteira_ativos, :update
    assert_permit @example_investor, @carteira_ativos, :destroy
  end

  test 'permissões para NÃO dono' do
    refute_permit @second_investor, :carteira_ativos, :index
    refute_permit @second_investor, @carteira_ativos, :show
    refute_permit @second_investor, @carteira_ativos, :new
    refute_permit @second_investor, @carteira_ativos, :create
    refute_permit @second_investor, @carteira_ativos, :edit
    refute_permit @second_investor, @carteira_ativos, :update
    refute_permit @second_investor, @carteira_ativos, :destroy
  end
end