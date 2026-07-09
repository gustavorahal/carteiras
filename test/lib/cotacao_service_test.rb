require 'test_helper'

class CotacaoServiceTest < ActiveSupport::TestCase
  test "ajusta_data: quando tipo ação e data hoje, retorna ultimo dia util" do
    travel_to Date.new(2021, 4, 19) # segunda feira
    data_teste = Date.today
    data_esperada = Date.new(2021, 4, 16) # sexta anterior
    data_retornada = CotacaoService._ajusta_data(data_teste, ativos(:itsa4).tipo)
    assert_equal data_esperada, data_retornada

    travel_to Date.new(2021, 4, 16) # sexta feira
    data_teste = Date.today
    data_esperada = Date.new(2021, 4, 15) # quinta
    data_retornada = CotacaoService._ajusta_data(data_teste, ativos(:itsa4).tipo)
    assert_equal data_esperada, data_retornada
  end

  test "ajusta_data: quando tipo ação e data passada no meio de semana, retorna o proprio dia" do
    travel_to Date.new(2021, 4, 16) # sexta feira
    data_teste = Date.today.prev_occurring(:friday) # uma semana atras
    data_esperada = data_teste
    data_retornada = CotacaoService._ajusta_data(data_teste, ativos(:itsa4).tipo)
    assert_equal data_esperada, data_retornada
  end

  test "ajusta_data: quando tipo tesouro e data hoje, retorna 2 dias uteis atrás" do
    travel_to Date.new(2021, 4, 19) # segunda feira
    data_teste = Date.today
    data_esperada = Date.new(2021, 4, 14) # quarta
    data_retornada = CotacaoService._ajusta_data(data_teste, ativos(:tesouro_selic).tipo)
    assert_equal data_esperada, data_retornada
  end

  test "ajusta_data: quando tipo tesouro e data hoje (uma terça), retorna 2 dias uteis atrás" do
    travel_to Date.new(2021, 4, 20) # terça feira
    data_teste = Date.today
    data_esperada = Date.new(2021, 4, 16) # sexta
    data_retornada = CotacaoService._ajusta_data(data_teste, ativos(:tesouro_selic).tipo)
    assert_equal data_esperada, data_retornada
  end

  test "ajusta_data: quando tipo tesouro e data passada no meio de semana, retorna o proprio dia" do
    data_teste = Date.new(2021, 4, 20) # terça feira
    data_esperada = data_teste
    data_retornada = CotacaoService._ajusta_data(data_teste, ativos(:tesouro_selic).tipo)
    assert_equal data_esperada, data_retornada
  end

  test "ajusta_data: quando tipo fundo e data hoje, retorna 3 dias uteis atrás" do
    travel_to Date.new(2021, 4, 19) # segunda feira
    data_teste = Date.today
    data_esperada = Date.new(2021, 4, 13) # terça
    data_retornada = CotacaoService._ajusta_data(data_teste, ativos(:fundo_dolar).tipo)
    assert_equal data_esperada, data_retornada
  end

  test "ajusta_data: quando tipo fundo e data hoje (uma quarta), retorna 3 dias uteis atrás" do
    travel_to Date.new(2021, 4, 21) # quarta feira
    data_teste = Date.today
    data_esperada = Date.new(2021, 4, 16) # sexta
    data_retornada = CotacaoService._ajusta_data(data_teste, ativos(:fundo_dolar).tipo)
    assert_equal data_esperada, data_retornada
  end

  test "ajusta_data: quando tipo fundo e data passada no meio de semana, retorna o proprio dia" do
    data_teste = Date.new(2021, 4, 20) # terça feira
    data_esperada = data_teste
    data_retornada = CotacaoService._ajusta_data(data_teste, ativos(:fundo_dolar).tipo)
    assert_equal data_esperada, data_retornada
  end

  test 'ativo_suportado?: ativo que existe' do
    BuscaCotacao::Facade.stub(:bolsa, BuscaCotacao::Resultado.new('AAPL', 100.0, Date.new(2021, 4, 16), 'test')) do
      suportado = CotacaoService.ativo_suportado?('AAPL', 'USD', 'acao')

      assert suportado, true
    end
  end

  test 'ativo_suportado?: ativo que NÃO existe' do
    BuscaCotacao::Facade.stub(:bolsa, nil) do
      suportado = CotacaoService.ativo_suportado?('NAOEXISTE', 'BRL', 'acao')

      assert_not suportado, true
    end
  end

  test 'cotacao: retorna nil quando não encontra cotação nem fallback no banco' do
    ativo = Ativo.new(nome: 'SEM_COTACAO', tipo: 'moeda', moeda_negociacao: 'BRL')

    BuscaCotacao::Facade.stub(:moeda, nil) do
      assert_nil CotacaoService.cotacao(ativo, Date.new(2021, 4, 19))
    end
  end

  test 'cotacao: retorna nil quando ativo não existe' do
    assert_nil CotacaoService.cotacao(nil, Date.new(2021, 4, 19))
  end

end
