require 'test_helper'

class CarteiraAtivosTest < ActiveSupport::TestCase
  test "lista ativos" do
    travel_to Date.new(2021, 4, 19) do
      ca = Posicao.new(carteiras(:example_growth), Date.today)
      assert ca.ativos.include?(ativos(:gndi3))
      assert ca.ativos.include?(ativos(:dis))
    end
  end
end
