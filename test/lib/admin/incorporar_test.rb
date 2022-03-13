require 'test_helper'

class IncorporarTest < ActiveSupport::TestCase

  def setup
    @ativo_incorporado = Ativo.create!(nome: 'AAPL', tipo: 1, moeda_negociacao: 'USD')
    @ativo_incorporadora = Ativo.create!(nome: 'MSFT', tipo: 1, moeda_negociacao: 'USD')
    @carteira = carteiras(:example_growth)
    @corretora = corretoras(:vitreo)
    @data1 = Date.new(2022,2,25)
    @data2 = Date.new(2022,3,2)
    @data_incorporacao = Date.new(2022,3,10)

    # Bootstrap diversos para tudo funcionar
    conta_correntes :vitreo_usd
    extratos :vitreo_usd_one
    # necessario haver ao menos 1 cotacao
    Cotacao.create!(ativo: @ativo_incorporado,
                    valor_unit: 10,
                    data: @data1 - 10.days)
    Cotacao.create!(ativo: @ativo_incorporadora,
                    valor_unit: 100,
                    data: @data1 - 10.days)
  end

  def checa_incorporacao(ativo_incorporado, ativo_incorporadora)

  end

  test 'incorporar ativo A em B sendo que B ja existe na carteira' do
    taxa = 5.26
    # Monta ativo_incorporado
    Operacao.create!(ativo: @ativo_incorporado, carteira: @carteira, corretora: @corretora, data: @data1,
                     valor_unit: 10, operacao: 'C', quantidade: 100, mon_ou_des: 'M')
    # faca uma segunda compra para avaliarmos o correto calculo de preco medio
    Operacao.create!(ativo: @ativo_incorporado, carteira: @carteira, corretora: @corretora, data: @data2,
                     valor_unit: 20, operacao: 'C', quantidade: 100)

    # Monta ativo_incorporadora
    Operacao.create!(ativo: @ativo_incorporadora, carteira: @carteira, corretora: @corretora, data: @data1,
                     valor_unit: 100, operacao: 'C', quantidade: 1000, mon_ou_des: 'M')

    Admin::Incorporar.incorporar(@ativo_incorporado, @ativo_incorporadora, taxa, @data_incorporacao)

    # Verificar
    ult_oper_ativo_incorporado = Operacao.where(ativo: @ativo_incorporado, carteira: @carteira).order(data: :desc).first
    assert_equal 'D', ult_oper_ativo_incorporado.mon_ou_des
    # o preco medio na desmontagem deveria ser 15, conforme operacoes de compra acima
    assert_equal 15, ult_oper_ativo_incorporado.valor_unit
    assert_equal 0, PosicaoAtivo.new(@carteira, @ativo_incorporado, @data_incorporacao).quantidade

    ult_oper_ativo_incorporadora = Operacao.where(ativo: @ativo_incorporadora, carteira: @carteira).order(data: :desc).first
    # como ja tinhamos ativo_incorporado na carteira, nao deveria ser uma operacao de montagem
    assert_not_equal 'M', ult_oper_ativo_incorporadora.mon_ou_des
    # o preco medio na desmontagem deveria ser 15, conforme operacoes de compra acima
    assert_equal 1052, ult_oper_ativo_incorporadora.quantidade
    assert_equal 2052, PosicaoAtivo.new(@carteira, @ativo_incorporadora, @data_incorporacao).quantidade
  end

  test 'incorporar ativo A em B sendo que B NAO existe na carteira' do
    taxa = 5
    # Monta ativo_incorporado
    Operacao.create!(ativo: @ativo_incorporado, carteira: @carteira, corretora: @corretora, data: @data1,
                     valor_unit: 10, operacao: 'C', quantidade: 100, mon_ou_des: 'M')
    # faca uma segunda compra para avaliarmos o correto calculo de preco medio
    Operacao.create!(ativo: @ativo_incorporado, carteira: @carteira, corretora: @corretora, data: @data2,
                     valor_unit: 20, operacao: 'C', quantidade: 100)

    Admin::Incorporar.incorporar(@ativo_incorporado, @ativo_incorporadora, taxa, @data_incorporacao)

    # Verificar
    ult_oper_ativo_incorporadora = Operacao.where(ativo: @ativo_incorporadora, carteira: @carteira).order(data: :desc).first
    # como ja tinhamos ativo_incorporado na carteira, nao deveria ser uma operacao de montagem
    assert_equal 'M', ult_oper_ativo_incorporadora.mon_ou_des
    # o preco medio na desmontagem deveria ser 15, conforme operacoes de compra acima
    assert_equal 1000, ult_oper_ativo_incorporadora.quantidade
    assert_equal 1000, PosicaoAtivo.new(@carteira, @ativo_incorporadora, @data_incorporacao).quantidade

  end

end