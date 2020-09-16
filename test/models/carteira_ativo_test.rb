require 'test_helper'

class CarteiraAtivoTest < ActiveSupport::TestCase
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
