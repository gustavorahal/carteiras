require "application_system_test_case"

class EspacosTest < ApplicationSystemTestCase
  test "usuário autenticado vê a seleção de espaços" do
    user = User.create!(email: "system@example.com", password: "segredo123")
    espaco = Espaco.create!(nome: "Uso pessoal")
    espaco.membros_espaco.create!(user:, papel: "administrador")
    visit new_user_session_path
    fill_in "user_email", with: user.email
    fill_in "user_password", with: "segredo123"
    find("input[type=submit]").click
    assert_text "Uso pessoal"
  end


  test "fluxo principal cria estrutura confirma corrige e reverte nota" do
    brl = Moeda.create!(codigo: "BRL", nome: "Real", casas_decimais: 2)
    instituicao = Instituicao.create!(nome: "Banco")
    ativo = Ativo.create!(codigo: "PETR4", mercado: "B3", tipo: "acao", moeda_negociacao: brl)
    user = User.create!(email: "fluxo@example.com", password: "segredo123")
    visit new_user_session_path
    fill_in "user_email", with: user.email
    fill_in "user_password", with: "segredo123"
    all("input[type=submit]").last.click

    click_link "Novo espaço"
    fill_in "espaco_nome", with: "Uso pessoal"
    all("input[type=submit]").last.click

    click_link "Novo investidor"
    fill_in "investidor_nome", with: "Pessoa"
    all("input[type=submit]").last.click

    click_link "Nova carteira"
    fill_in "carteira_nome", with: "Principal"
    select "BRL", from: "carteira_moeda_base_id"
    all("input[type=submit]").last.click

    click_link "Nova conta"
    fill_in "conta_investimento_nome", with: "Conta"
    select instituicao.nome, from: "conta_investimento_instituicao_id"
    check "BRL"
    all("input[type=submit]").last.click

    visit espacos_path
    click_link "Uso pessoal"
    click_link "Transações"
    click_button "Nova transação"
    click_link "Nota de negociação"
    select "Pessoa", from: "investidor_id"
    select "Conta · BRL", from: "atributos_conta_caixa_id"
    select ativo.codigo, from: "atributos[negociacoes][][ativo_id]"
    find("input[name='atributos[negociacoes][][quantidade]']").set("10")
    find("input[name='atributos[negociacoes][][preco_unitario]']").set("10")
    click_button "Criar rascunho"
    accept_confirm { click_button "Confirmar transação" }
    url_original = page.current_url
    visit espacos_path
    click_link "Uso pessoal"
    click_link "Principal"
    assert_text "PETR4"
    grupo = find("button[data-action='category-groups#toggle']")
    assert_equal "true", grupo["aria-expanded"]
    grupo.click
    assert_equal "false", grupo["aria-expanded"]
    assert_no_selector "tr[data-category-groups-target=row]", visible: true
    grupo.click
    assert_selector "tr[data-category-groups-target=row]", visible: true

    visit url_original
    click_link "Corrigir"
    find("input[name='atributos[negociacoes][][quantidade]']").set("12")
    click_button "Aplicar correção"
    accept_confirm { click_button "Reverter" }
    visit espacos_path
    click_link "Uso pessoal"
    click_link "Principal"
    assert_no_text "PETR4"
  end

  test "interface principal se adapta a uma tela móvel sem rolagem horizontal" do
    user = User.create!(email: "mobile@example.com", password: "segredo123")
    espaco = Espaco.create!(nome: "Uso móvel")
    espaco.membros_espaco.create!(user:, papel: "administrador")
    page.driver.browser.manage.window.resize_to(390, 844)

    visit new_user_session_path
    assert_selector ".auth-card"
    fill_in "E-mail", with: user.email
    fill_in "Senha", with: "segredo123"
    click_button "Entrar"

    assert_selector ".navbar-toggler"
    assert_text "Uso móvel"
    largura = page.evaluate_script("document.documentElement.scrollWidth")
    viewport = page.evaluate_script("document.documentElement.clientWidth")
    assert_operator largura, :<=, viewport
  end
end
