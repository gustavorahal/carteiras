require "test_helper"

class FluxosHttpTest < ActionDispatch::IntegrationTest
  setup do
    @brl = Moeda.create!(codigo: "BRL", nome: "Real", casas_decimais: 2)
    FonteCotacao.create!(codigo: "MANUAL", nome: "Manual")
    FonteCotacao.create!(codigo: "BRAPI", nome: "brapi.dev")
    @usuario = User.create!(email: "web@example.com", password: "segredo123")
    @estranho = User.create!(email: "outro@example.com", password: "segredo123")
    @admin_sistema = User.create!(email: "root@example.com", password: "segredo123", administrador_sistema: true)
    @espaco = Espaco.create!(nome: "Web")
    @espaco.membros_espaco.create!(user: @usuario, papel: "administrador")
    @investidor = @espaco.investidores.create!(nome: "Pessoa")
    @instituicao = Instituicao.create!(nome: "Banco")
    @carteira = @investidor.carteiras.create!(nome: "Principal", moeda_base: @brl)
    @conta = @carteira.contas_investimento.create!(nome: "Conta", instituicao: @instituicao)
    @caixa = @conta.contas_caixa.create!(moeda: @brl)
    @ativo = Ativo.create!(codigo: "PETR4", mercado: "B3", tipo: "acao", moeda_negociacao: @brl)
  end

  test "usuário cria espaço e vira primeiro administrador" do
    sign_in @estranho
    assert_difference(["Espaco.count", "MembroEspaco.count"], 1) do
      post espacos_path, params: { espaco: { nome: "Novo" } }
    end
    assert_redirected_to espaco_path(Espaco.order(:id).last)
    assert_equal "administrador", Espaco.order(:id).last.membros_espaco.first.papel
  end

  test "adulteração de espaço não atravessa escopo" do
    sign_in @estranho
    get espaco_path(@espaco)
    assert_response :not_found
  end

  test "administrador adiciona usuário existente por email" do
    sign_in @usuario
    post espaco_membros_path(@espaco), params: { membro_espaco: { email: @estranho.email, papel: "editor" } }
    assert_redirected_to espaco_path(@espaco)
    assert_equal "editor", @espaco.membros_espaco.find_by!(user: @estranho).papel
  end


  test "formulário de nota renderiza linhas dinâmicas e correção vem preenchida" do
    sign_in @usuario
    get new_espaco_transacao_path(@espaco, tipo: "nota_negociacao", investidor_id: @investidor.id)
    assert_response :success
    assert_select "[data-controller=negociacoes]"
    atributos = { conta_caixa_id: @caixa.id, data_negociacao: "2026-01-05", data_liquidacao: "2026-01-05",
      custo_operacional_total: "0", taxa_conversao_base: "1",
      negociacoes: [{ ativo_id: @ativo.id, natureza: "compra", quantidade: "10", preco_unitario: "10" }] }
    transacao = TransacoesFinanceiras.criar_rascunho(tipo: "nota_negociacao", investidor: @investidor,
      usuario: @usuario, atributos:)
    TransacoesFinanceiras.confirmar(transacao:, usuario: @usuario)
    get correcao_espaco_transacao_path(@espaco, transacao)
    assert_response :success
    assert_select "input[name='atributos[negociacoes][][quantidade]'][value='10.0']"
  end


  test "painel e formulário de conta renderizam sem N mais um estrutural" do
    sign_in @usuario
    get espaco_investidor_carteira_path(@espaco, @investidor, @carteira)
    assert_response :success
    get new_espaco_investidor_carteira_conta_path(@espaco, @investidor, @carteira)
    assert_response :success
  end

  test "área administrativa renderiza catálogo global" do
    sign_in @admin_sistema
    get admin_ativos_path
    assert_response :success
    get new_admin_ativo_path
    assert_response :success
  end

  test "checagem de autorização precede busca de usuário por email" do
    editor = User.create!(email: "editor-web@example.com", password: "segredo123")
    @espaco.membros_espaco.create!(user: editor, papel: "editor")
    sign_in editor

    post espaco_membros_path(@espaco), params: { membro_espaco: { email: "ausente@example.com", papel: "leitor" } }
    assert_response :forbidden
    post espaco_membros_path(@espaco), params: { membro_espaco: { email: @estranho.email, papel: "leitor" } }
    assert_response :forbidden
  end

  test "rebaixamento do último administrador é rejeitado sem erro 500" do
    sign_in @usuario
    membro = @espaco.membros_espaco.find_by!(user: @usuario)
    patch espaco_membro_path(@espaco, membro), params: { membro_espaco: { papel: "editor" } }

    assert_redirected_to espaco_path(@espaco)
    assert_equal "administrador", membro.reload.papel
    assert_match(/último administrador/, flash[:alert])
  end

  test "lista filtra transações por carteira sem N mais um de investidor" do
    criar_transacao = lambda do |caixa, data|
      transacao = TransacoesFinanceiras.criar_rascunho(tipo: "movimentacao_caixa", investidor: @investidor,
        usuario: @usuario, atributos: { tipo_movimentacao: "aporte", conta_caixa_destino_id: caixa.id,
          valor: "10", data_efetiva: data })
      TransacoesFinanceiras.confirmar(transacao:, usuario: @usuario)
    end
    outra_carteira = @investidor.carteiras.create!(nome: "Reserva", moeda_base: @brl)
    outra_conta = outra_carteira.contas_investimento.create!(nome: "Outra", instituicao: @instituicao)
    outro_caixa = outra_conta.contas_caixa.create!(moeda: @brl)
    original = criar_transacao.call(@caixa, "2026-01-02")
    reversao = TransacoesFinanceiras.reverter(transacao: original, usuario: @usuario)
    criar_transacao.call(outro_caixa, "2026-01-03")
    sign_in @usuario

    get espaco_transacoes_path(@espaco), params: { carteira_id: @carteira.id }
    assert_response :success
    assert_match(/2026-01-02/, response.body)
    assert_no_match(/2026-01-03/, response.body)
    assert_match(/#{espaco_transacao_path(@espaco, reversao)}/, response.body)
  end

  test "rascunho exibe prévia e edição pode recalculá-la antes de confirmar" do
    rascunho = TransacoesFinanceiras.criar_rascunho(tipo: "nota_negociacao", investidor: @investidor,
      usuario: @usuario, atributos: { conta_caixa_id: @caixa.id, data_negociacao: "2026-01-05",
        data_liquidacao: "2026-01-05", custo_operacional_total: "0", taxa_conversao_base: "1",
        negociacoes: [{ ativo_id: @ativo.id, natureza: "compra", quantidade: "1", preco_unitario: "10" }] })
    sign_in @usuario

    get espaco_transacao_path(@espaco, rascunho)
    assert_response :success
    assert_select "h2", text: "Prévia antes da confirmação"
    post prever_espaco_transacoes_path(@espaco), params: { id: rascunho.id, investidor_id: @investidor.id,
      tipo: "nota_negociacao", atributos: { conta_caixa_id: @caixa.id, data_negociacao: "2026-01-05",
        data_liquidacao: "2026-01-05", custo_operacional_total: "0", taxa_conversao_base: "1",
        negociacoes: [{ ativo_id: @ativo.id, natureza: "compra", quantidade: "2", preco_unitario: "10" }],
        ordem_na_data: "" } }
    assert_response :success
    assert_match(/posicoes_resultantes/, response.body)
  end

  test "prévia de correção substitui a original em vez de somar as duas" do
    original = TransacoesFinanceiras.criar_rascunho(tipo: "nota_negociacao", investidor: @investidor,
      usuario: @usuario, atributos: { conta_caixa_id: @caixa.id, data_negociacao: "2026-01-05",
        data_liquidacao: "2026-01-05", custo_operacional_total: "0", taxa_conversao_base: "1",
        negociacoes: [{ ativo_id: @ativo.id, natureza: "compra", quantidade: "10", preco_unitario: "10" }] })
    TransacoesFinanceiras.confirmar(transacao: original, usuario: @usuario)
    sign_in @usuario

    post prever_espaco_transacoes_path(@espaco), params: { id: original.id, correcao: "1",
      investidor_id: @investidor.id, tipo: "nota_negociacao", atributos: { conta_caixa_id: @caixa.id,
        data_negociacao: "2026-01-05", data_liquidacao: "2026-01-05", custo_operacional_total: "0",
        taxa_conversao_base: "1", negociacoes: [{ ativo_id: @ativo.id, natureza: "compra",
          quantidade: "12", preco_unitario: "10" }], ordem_na_data: original.ordem_na_data } }

    assert_response :success
    assert_match(/&quot;quantidade&quot;: &quot;12\.0&quot;/, response.body)
    assert_no_match(/&quot;quantidade&quot;: &quot;22\.0&quot;/, response.body)
  end

  test "cotação inválida retorna 422 preservando o payload" do
    sign_in @admin_sistema
    post admin_cotacoes_ativos_path, params: { cotacao_ativo: {
      ativo_id: @ativo.id, data: "2026-01-05", preco: "inválido" } }

    assert_response :unprocessable_content
    assert_select "input[name='cotacao_ativo[preco]'][value='inválido']"
  end
end
