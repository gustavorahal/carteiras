require 'test_helper'

class ReferenciaAtivoPolicyTest < ActiveSupport::TestCase
  setup do
    @admin = users :admin
    @example_investor = users :example_investor
    @second_investor = users :second_investor
    @referencia_ativo = referencia_ativos :itsa4
  end
  
  test 'permissões de admin' do
    assert_permit @admin, :referencia_ativo, :index
    assert_permit @admin, @referencia_ativo, :show
    assert_permit @admin, @referencia_ativo, :new
    assert_permit @admin, @referencia_ativo, :create
    assert_permit @admin, @referencia_ativo, :edit
    assert_permit @admin, @referencia_ativo, :update
    assert_permit @admin, @referencia_ativo, :destroy
  end

  test 'nenhum usuário pode acessar' do
    refute_permit @example_investor, :referencia_ativo, :index
    refute_permit @example_investor, @referencia_ativo, :show
    refute_permit @example_investor, @referencia_ativo, :new
    refute_permit @example_investor, @referencia_ativo, :create
    refute_permit @example_investor, @referencia_ativo, :edit
    refute_permit @example_investor, @referencia_ativo, :update
    refute_permit @example_investor, @referencia_ativo, :destroy

    refute_permit @second_investor, :referencia_ativo, :index
    refute_permit @second_investor, @referencia_ativo, :show
    refute_permit @second_investor, @referencia_ativo, :new
    refute_permit @second_investor, @referencia_ativo, :create
    refute_permit @second_investor, @referencia_ativo, :edit
    refute_permit @second_investor, @referencia_ativo, :update
    refute_permit @second_investor, @referencia_ativo, :destroy
  end
end