require 'test_helper'

class PosicaoPolicyTest < ActiveSupport::TestCase
  setup do
    @admin = users :admin
    @example_investor = users :example_investor
    @second_investor = users :second_investor
    @posicao = Posicao.new(carteiras(:example_growth), Date.today)
  end
  
  test 'permissões de admin' do
    assert_permit @admin, :posicao, :index
    assert_permit @admin, @posicao, :show
    assert_permit @admin, @posicao, :new
    assert_permit @admin, @posicao, :create
    assert_permit @admin, @posicao, :edit
    assert_permit @admin, @posicao, :update
    assert_permit @admin, @posicao, :destroy
  end

  test 'permissões para dono' do
    refute_permit @example_investor, :posicao, :index
    assert_permit @example_investor, @posicao, :show
    assert_permit @example_investor, @posicao, :new
    assert_permit @example_investor, @posicao, :create
    assert_permit @example_investor, @posicao, :edit
    assert_permit @example_investor, @posicao, :update
    assert_permit @example_investor, @posicao, :destroy
  end

  test 'permissões para NÃO dono' do
    refute_permit @second_investor, :posicao, :index
    refute_permit @second_investor, @posicao, :show
    refute_permit @second_investor, @posicao, :new
    refute_permit @second_investor, @posicao, :create
    refute_permit @second_investor, @posicao, :edit
    refute_permit @second_investor, @posicao, :update
    refute_permit @second_investor, @posicao, :destroy
  end
end