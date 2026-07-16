require "test_helper"

class FluxosPrincipaisTest < ActionDispatch::IntegrationTest
  test "painel, linha do tempo e formulário tipado renderizam sem consultas externas" do
    sign_in @usuario
    get carteira_path(@carteira)
    assert_response :success
    get carteira_eventos_financeiros_path(@carteira)
    assert_response :success
    EventosFinanceirosController::TIPOS_CADASTRAVEIS.each do |tipo|
      get new_carteira_eventos_financeiro_path(@carteira, tipo:)
      assert_response :success
      assert_select "input[name='evento_financeiro[tipo]'][value='#{tipo}']"
    end
  end

  test "reversão não pode ser criada pelo formulário genérico" do
    sign_in @usuario
    post carteira_eventos_financeiros_path(@carteira), params: {
      evento_financeiro: { tipo: "reversao", data_competencia: Date.current },
      detalhe: {}
    }

    assert_response :unprocessable_entity
    assert_equal 0, @carteira.eventos_financeiros.count
  end

  test "cadastro de contas normaliza identificador vazio e cria caixas selecionados" do
    sign_in @usuario
    2.times do |indice|
      post carteira_contas_investimento_index_path(@carteira), params: {
        conta_investimento: { nome: "Nova #{indice}", corretora_id: @corretora.id,
          identificador_externo: "", moeda_ids: [@brl.id, @usd.id] }
      }
      assert_response :redirect
    end
    contas = @carteira.contas_investimento.where("nome LIKE 'Nova %'").order(:nome)
    assert_equal [nil, nil], contas.pluck(:identificador_externo)
    assert_equal [2, 2], contas.map { |conta| conta.contas_caixa.count }
  end

  test "telas históricas, relatórios e importação são utilizáveis" do
    sign_in @usuario
    [carteira_posicao_historica_path(@carteira), carteira_rentabilidade_path(@carteira),
      carteira_comparacao_referencia_path(@carteira), carteira_ganho_de_capital_path(@carteira),
      carteira_posicao_ano_anterior_path(@carteira),
      new_carteira_importacoes_extrato_path(@carteira),
      new_carteira_contas_investimento_path(@carteira),
      edit_carteira_contas_investimento_path(@carteira, @conta)].each do |caminho|
      get caminho
      assert_response :success
    end
  end
end
