require 'test_helper'

class DesdobraGrupaTest < ActiveSupport::TestCase

  def setup
    Config.create!(nome: "busca_cotacao_bolsa", valor: "false")
    @ativo = Ativo.create!(nome: 'TEST3', tipo: 'acao', moeda_negociacao: 'BRL')
    @carteira = carteiras(:example_growth)
    @corretora = corretoras(:vitreo)
    @data_compra = Date.new(2022, 2, 25)
    @data_evento = Date.new(2022, 3, 10)

    conta_correntes(:vitreo_brl)
    extratos(:two_processado)

    Cotacao.create!(ativo: @ativo, valor_unit: 10, data: @data_evento)
  end

  test 'desdobrar remonta posição na mesma corretora' do
    Operacao.create!(ativo: @ativo, carteira: @carteira, corretora: @corretora, data: @data_compra,
                     valor_unit: 10, operacao: 'C', quantidade: 100, mon_ou_des: 'M')

    Admin::DesdobraGrupa.desdobrar(@ativo, 2, @data_evento)

    montagem = Operacao.where(ativo: @ativo, carteira: @carteira).order(:data, :created_at).last

    assert_equal @corretora, montagem.corretora
    assert_equal 'C', montagem.operacao
    assert_equal 'M', montagem.mon_ou_des
    assert_equal 200, montagem.quantidade
    assert_equal 5, montagem.valor_unit
    assert_equal 200, PosicaoAtivo.new(@carteira, @ativo, @data_evento).quantidade
  end

  test 'grupar remonta posição na mesma corretora' do
    Operacao.create!(ativo: @ativo, carteira: @carteira, corretora: @corretora, data: @data_compra,
                     valor_unit: 10, operacao: 'C', quantidade: 100, mon_ou_des: 'M')

    Admin::DesdobraGrupa.grupar(@ativo, 2, @data_evento)

    montagem = Operacao.where(ativo: @ativo, carteira: @carteira).order(:data, :created_at).last

    assert_equal @corretora, montagem.corretora
    assert_equal 'C', montagem.operacao
    assert_equal 'M', montagem.mon_ou_des
    assert_equal 50, montagem.quantidade
    assert_equal 20, montagem.valor_unit
    assert_equal 50, PosicaoAtivo.new(@carteira, @ativo, @data_evento).quantidade
  end

end
