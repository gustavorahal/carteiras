require 'test_helper'

class ProcessaProventosTest < ActiveSupport::TestCase
  setup do
    skip "Os fixtures privados de extratos de corretoras foram removidos do repositorio publico."
  end

  test "vitreo: processa dividendo" do
    proventos = _test_processa_proventos :vitreo_brl, file_path('extrato_vitreo.xlsx')
    assert proventos.find_by(ativo: ativos(:petr4), evento: 'dividendo', valor_liquido: 321.98).present?
  end

  test "vitreo: processa JCP" do
    proventos = _test_processa_proventos :vitreo_brl, file_path('extrato_vitreo.xlsx')
    assert proventos.find_by(ativo: ativos(:bpac11), evento: 'jcp', valor_liquido: 72.21).present?
  end

  test "vitreo: processa rendimentos FII" do
    proventos = _test_processa_proventos :vitreo_brl, file_path('extrato_vitreo.xlsx')
    assert proventos.find_by(ativo: ativos(:rbrr11), evento: 'rendimento', valor_liquido: 60.80).present?
  end

  test "xp: processa dividendo" do
    proventos = _test_processa_proventos :xp_brl, file_path('extrato_xp.xlsx')
    assert proventos.find_by(ativo: ativos(:itsa4), evento: 'dividendo',
                            quantidade: 402, valor_liquido: 8.04).present?
    assert proventos.find_by(ativo: ativos(:bpan4), evento: 'dividendo',
                            quantidade: 3700, valor_liquido: 26.91).present?
  end

  test "xp: processa JCP" do
    proventos = _test_processa_proventos :xp_brl, file_path('extrato_xp.xlsx')
    assert proventos.find_by(ativo: ativos(:itsa4), evento: 'jcp',
                             quantidade: 2, valor_liquido: 0.04).present?


  end

  test "xp: processa rendimentos FII" do
    proventos = _test_processa_proventos :xp_brl, file_path('extrato_xp.xlsx')
    assert proventos.find_by(ativo: ativos(:rbrf11), evento: 'rendimento',
                             quantidade: 12, valor_liquido: 9.00).present?
  end

  #
  # Private
  #

  def _test_processa_proventos(cc_symbol, arquivo_import)
    conta_corrente = conta_correntes cc_symbol
    Extratos::Importa.importar conta_corrente, arquivo_import
    Extratos::Processa.processar conta_corrente

    Provento.where(carteira: conta_corrente.carteira, corretora: conta_corrente.corretora)
  end

end
