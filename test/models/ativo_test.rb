require 'test_helper'

class AtivoTest < ActiveSupport::TestCase
  test "ativo NÃO suportado" do
    CotacaoService.stub(:ativo_suportado?, false) do
      ativo = Ativo.new(nome: 'Nao existe', tipo: 'acao', moeda_negociacao: 'BRL')
      assert_raises ActiveRecord::RecordNotSaved do
        ativo.save!
      end

      assert ativo.errors.full_messages[0] == 'Ativo não é suportado porque não conseguimos obter cotações'
    end
  end

  test "ativo suportado" do
    CotacaoService.stub(:ativo_suportado?, true) do
      ativo = Ativo.new(nome: 'AAPL', tipo: 'acao', moeda_negociacao: 'USD')
      ativo.save!

      assert_predicate ativo, :persisted?
    end
  end

end
