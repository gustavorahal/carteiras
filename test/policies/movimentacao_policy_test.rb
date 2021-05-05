require 'test_helper'

class MovimentacaoPolicyTest < ActiveSupport::TestCase
  setup do
    @admin = users :admin
    @example_investor = users :example_investor
    @second_investor = users :second_investor
    @movimentacao = movimentacoes :entrada
  end
  
  test 'permissões de admin' do
    assert_permit @admin, :movimentacao, :index
    assert_permit @admin, @movimentacao, :show
    assert_permit @admin, @movimentacao, :new
    assert_permit @admin, @movimentacao, :create
    assert_permit @admin, @movimentacao, :edit
    assert_permit @admin, @movimentacao, :update
    assert_permit @admin, @movimentacao, :destroy
  end

  test 'permissões para dono' do
    refute_permit @example_investor, :movimentacao, :index
    assert_permit @example_investor, @movimentacao, :show
    assert_permit @example_investor, @movimentacao, :new
    assert_permit @example_investor, @movimentacao, :create
    assert_permit @example_investor, @movimentacao, :edit
    assert_permit @example_investor, @movimentacao, :update
    assert_permit @example_investor, @movimentacao, :destroy
  end

  test 'permissões para NÃO dono' do
    refute_permit @second_investor, :movimentacao, :index
    refute_permit @second_investor, @movimentacao, :show
    refute_permit @second_investor, @movimentacao, :new
    refute_permit @second_investor, @movimentacao, :create
    refute_permit @second_investor, @movimentacao, :edit
    refute_permit @second_investor, @movimentacao, :update
    refute_permit @second_investor, @movimentacao, :destroy
  end
end