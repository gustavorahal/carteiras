require 'test_helper'

class AtivoTest < ActiveSupport::TestCase
  test "ativo NÃO suportado" do
    ativo = Ativo.new(nome: 'Nao existe', tipo: 'acao', moeda: 'BRL')
    assert_raises ActiveRecord::RecordNotSaved do
      ativo.save!
    end
    
    assert ativo.errors.full_messages[0] == 'Ativo não é suportado porque não conseguimos obter cotações'
  end

  test "ativo suportado" do
    ativo = Ativo.new(nome: 'ITSA4', tipo: 'acao', moeda: 'BRL')
    ativo.save!
  end

end
