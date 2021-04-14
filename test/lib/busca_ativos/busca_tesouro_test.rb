require 'test_helper'

class BuscaTesouroTest < ActiveSupport::TestCase
  test "busca LFT 2027" do
    nome_titulo_app = 'Tesouro Selic 2027'
    data = Date.new(2021,3,18)
    dados = BuscaCotacao::Tesouro.busca(nome_titulo_app, Date.new(2021, 3, 18))
    # Dados buscados na planilha
    # 18/03/2021	0,35%	0,36%	10.583,62	10.577,38	10.576,09

    assert dados[data], 10577.38

  end
end