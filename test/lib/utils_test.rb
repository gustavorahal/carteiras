require 'test_helper'

class UtilsTest < ActiveSupport::TestCase
  test "ultimo dia util: se hoje segunda, retorna sexta" do
    travel_to Date.new(2021, 4, 19)
    data_teste = Date.today
    data_esperada = Date.new(2021, 4, 16)
    data_retornada = Utils.ultimo_dia_util(data_teste)
    assert_equal data_esperada, data_retornada
  end

  test "ultimo dia util: se data no passado dia util, retorna ela mesma" do
    travel_to Date.new(2021, 4, 16)
    data_teste = Date.new(2021, 4, 14)
    data_esperada = Date.new(2021, 4, 14)
    data_retornada = Utils.ultimo_dia_util(data_teste)
    assert_equal data_esperada, data_retornada
  end

  test "ultimo dia util: se data no passado final de semana, retorna dia util anterior" do
    travel_to Date.new(2021, 4, 18) # domingo "hoje"
    data_teste = Date.new(2021, 4, 11) # domingo anterior
    data_esperada = Date.new(2021, 4, 9) # sexta
    data_retornada = Utils.ultimo_dia_util(data_teste)
    assert_equal data_esperada, data_retornada
  end

  test "ultimo dia util: se hoje final de semana, retorna dia util anterior" do
    travel_to Date.new(2021, 4, 18) # domingo
    data_teste = Date.today
    data_esperada = Date.new(2021, 4, 16) # sexta
    data_retornada = Utils.ultimo_dia_util(data_teste)
    assert_equal data_esperada, data_retornada
  end

  test "ultimo dia util: se hoje feriado, retorna ultimo dia util" do
    travel_to Date.new(2020, 5, 1) # dia do trabalho, uma sexta-feira
    data_teste = Date.today
    data_esperada = Date.new(2020, 4, 30) # quinta
    data_retornada = Utils.ultimo_dia_util(data_teste)
    assert_equal data_esperada, data_retornada
  end

end
