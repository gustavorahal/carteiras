require 'test_helper'

class PosicaoAtivoTest < ActiveSupport::TestCase
  test "calcula valor investido" do
    # inspirado em histórico de GNDI3 (ativo 124) example portfolio]
    ap = PosicaoAtivo.new(carteiras(:example_growth), ativos(:gndi3), Date.today)
    assert_in_delta ap.valor_investido, 7410.0
  end
end