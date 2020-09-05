require 'test_helper'

class CarteiraAtivoTest < ActiveSupport::TestCase
  # test 'Não permitir desativar carteira ativo se presente na carteira' do
  #   ca = carteira_ativos :itsa4_example_growth
  #   assert ca.quantidade == 200
  #   ca.valido = false
  #   assert_raise(ActiveRecord::RecordNotSaved) do
  #     ca.save!
  #   end
  # end
  #
  # test 'permitir desativar carteira ativo se não faz mais parte da carteira' do
  #   ca = carteira_ativos :bpan4_example_growth
  #   assert ca.quantidade.zero?
  #   ca.valido = false
  #   ca.save!
  # end

  test 'Não permitir adicionar um mesmo carteira ativo (mesmo ativo, carteira e corretora)' do
    carteira_ativos :bpan4_example_growth

    # Se for mesmo ativo, carteira ou corretora, falhar
    assert_raise(ActiveRecord::RecordInvalid) do
      CarteiraAtivo.create!(ativo: ativos(:bpan4),
                                  carteira: carteiras(:example_growth),
                                  corretora: corretoras(:xp),
                                  book: 'Ações')
    end

    # Se for outra corretora, tudo certo
    CarteiraAtivo.create!(ativo: ativos(:bpan4),
                                carteira: carteiras(:example_growth),
                                corretora: corretoras(:avenue),
                                book: 'Ações')

    # Se for outra carteira, tudo certo
    CarteiraAtivo.create!(ativo: ativos(:bpan4),
                          carteira: carteiras(:example_income),
                          corretora: corretoras(:xp),
                          book: 'Ações')
  end

end
