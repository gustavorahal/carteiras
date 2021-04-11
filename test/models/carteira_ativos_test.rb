require 'test_helper'

class CarteiraAtivosTest < ActiveSupport::TestCase
  test "lista ativos" do
    ca = CarteiraAtivos.new(carteiras(:example_growth), Date.today)
    assert ca.ativos.include?(ativos(:gndi3))
    assert ca.ativos.include?(ativos(:dis))
  end
end