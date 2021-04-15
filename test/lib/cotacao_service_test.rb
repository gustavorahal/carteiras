require 'test_helper'

class CotacaoServiceTest < ActiveSupport::TestCase
  test "ajusta data: quando tipo ação e data hoje, retorna ultimo dia util" do
    data_teste = Date.today
    data_esperada = data_teste.on_weekend? ? data_teste.prev_weekday : data_teste - 1
    data_retornada = CotacaoService._ajusta_data(data_teste, ativos(:itsa4))
    assert_equal data_esperada, data_retornada
  end

  test "ajusta data: quando tipo ação e data passada no meio de semana, retorna o proprio dia" do
    data_teste = Date.today.prev_occurring(:tuesday)
    data_esperada = data_teste
    data_retornada = CotacaoService._ajusta_data(data_teste, ativos(:itsa4))
    assert_equal data_esperada, data_retornada
  end

  test "ajusta data: quando tipo tesouro e data hoje, retorna 2 dias uteis atrás" do
    data_teste = Date.today
    data_esperada = data_teste.on_weekend? ? data_teste.prev_weekday - 2 : data_teste - 2
    data_retornada = CotacaoService._ajusta_data(data_teste, ativos(:tesouro_selic))
    assert_equal data_esperada, data_retornada
  end

  test "ajusta data: quando tipo tesouro e data passada no meio de semana, retorna o proprio dia" do
    data_teste = Date.today.prev_occurring(:tuesday)
    data_esperada = data_teste
    data_retornada = CotacaoService._ajusta_data(data_teste, ativos(:tesouro_selic))
    assert_equal data_esperada, data_retornada
  end

  test "ajusta data: quando tipo fundo e data hoje, retorna 3 dias uteis atrás" do
    data_teste = Date.today
    data_esperada = data_teste.on_weekend? ? data_teste.prev_weekday - 3 : data_teste - 3
    data_retornada = CotacaoService._ajusta_data(data_teste, ativos(:fundo_dolar))
    assert_equal data_esperada, data_retornada
  end

  test "ajusta data: quando tipo fundo e data passada no meio de semana, retorna o proprio dia" do
    data_teste = Date.today.prev_occurring(:tuesday)
    data_esperada = data_teste
    data_retornada = CotacaoService._ajusta_data(data_teste, ativos(:fundo_dolar))
    assert_equal data_esperada, data_retornada
  end
end