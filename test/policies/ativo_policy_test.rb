require 'test_helper'

class AtivoPolicyTest < ActiveSupport::TestCase
  setup do
    @admin = users :admin
    @example_investor = users :example_investor
    @second_investor = users :second_investor
    @ativo = ativos :itsa4
  end
  
  test 'permissões de admin' do
    assert_permit @admin, :ativo, :index
    assert_permit @admin, @ativo, :show
    assert_permit @admin, @ativo, :new
    assert_permit @admin, @ativo, :create
    assert_permit @admin, @ativo, :edit
    assert_permit @admin, @ativo, :update
    assert_permit @admin, @ativo, :destroy
  end

  test 'permissões para investidor no geral' do
    assert_permit @example_investor, :ativo, :index
    assert_permit @example_investor, @ativo, :show
    refute_permit @example_investor, @ativo, :new
    refute_permit @example_investor, @ativo, :create
    refute_permit @example_investor, @ativo, :edit
    refute_permit @example_investor, @ativo, :update
    refute_permit @example_investor, @ativo, :destroy
  end
end