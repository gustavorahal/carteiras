require 'test_helper'

class CarteiraAtivoTest < ActiveSupport::TestCase
  test 'Não permitir desativar carteira ativo se presente na carteira' do
    ca = carteira_ativos :itsa4_example_growth
    assert ca.quantidade == 200
    ca.valido = false
    assert_raise(ActiveRecord::RecordNotSaved) do
      ca.save!
    end
  end

  test 'permitir desativar carteira ativo se não faz mais parte da carteira' do
    ca = carteira_ativos :bpan4_example_growth
    assert ca.quantidade.zero?
    ca.valido = false
    ca.save!
  end


end
