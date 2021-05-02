require 'test_helper'

class CotacaoPolicyTest < ActiveSupport::TestCase
  setup do
    @admin = users :admin
    @example_investor = users :example_investor
    @second_investor = users :second_investor
    @cotacao = cotacoes :itsa4
  end
  
  test 'permissões de admin' do
    assert_permit @admin, :cotacao, :index
    assert_permit @admin, @cotacao, :show
    assert_permit @admin, @cotacao, :new
    assert_permit @admin, @cotacao, :create
    assert_permit @admin, @cotacao, :edit
    assert_permit @admin, @cotacao, :update
    assert_permit @admin, @cotacao, :destroy
  end

  test 'permissões para investidor em geral' do
    assert_permit @example_investor, :cotacao, :index
    assert_permit @example_investor, @cotacao, :show
    refute_permit @example_investor, @cotacao, :new
    refute_permit @example_investor, @cotacao, :create
    refute_permit @example_investor, @cotacao, :edit
    refute_permit @example_investor, @cotacao, :update
    refute_permit @example_investor, @cotacao, :destroy
  end

end