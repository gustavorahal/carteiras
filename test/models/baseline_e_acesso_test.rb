require "test_helper"

class BaselineEAcessoTest < ActiveSupport::TestCase
  TABELAS = %w[users espacos membros_espaco investidores carteiras contas_investimento contas_caixa moedas instituicoes ativos fontes_cotacao transacoes_financeiras notas_negociacao negociacoes proventos movimentacoes_caixa lancamentos_caixa posicoes_atuais cotacoes_ativos cotacoes_cambio].sort.freeze

  test "banco primário tem exatamente as vinte tabelas funcionais" do
    funcionais = ActiveRecord::Base.connection.tables - %w[schema_migrations ar_internal_metadata]
    assert_equal TABELAS, funcionais.sort
  end

  test "normaliza códigos nomes e campos opcionais" do
    moeda = Moeda.create!(codigo: " eur ", nome: " Euro ", casas_decimais: 2)
    assert_equal "EUR", moeda.codigo
    assert_equal "Euro", moeda.nome
    conta = @carteira.contas_investimento.create!(nome: " Outra ", instituicao: @instituicao, identificador_externo: " ")
    assert_nil conta.identificador_externo
  end

  test "protege último administrador sob lock" do
    membro = @espaco.membros_espaco.find_by!(user: @usuario)
    assert_not membro.destroy
    assert_match(/último administrador/, membro.errors.full_messages.to_sentence)
    @espaco.membros_espaco.create!(user: @estranho, papel: "administrador")
    assert membro.destroy
  end

  test "escopo de espaço isola usuário sem vínculo e admin do sistema vê tudo" do
    assert_equal [@espaco], EspacoPolicy::Scope.new(@usuario, Espaco).resolve.to_a
    assert_empty EspacoPolicy::Scope.new(@estranho, Espaco).resolve
    assert_equal [@espaco], EspacoPolicy::Scope.new(@admin_sistema, Espaco).resolve.to_a
  end

  test "leitor consulta mas não cria fatos" do
    assert ConsultasFinanceiras.saldos_caixa(carteira: @carteira, data: Date.current, usuario: @leitor)
    assert_raises(Financeiro::NaoAutorizado) do
      TransacoesFinanceiras.criar_rascunho(tipo: "movimentacao_caixa", investidor: @investidor, usuario: @leitor, atributos: atributos_aporte)
    end
  end

  test "cadastro arquivado não aceita novo fato" do
    @caixa_brl.arquivar!
    assert_raises(Financeiro::RegistroArquivado) do
      TransacoesFinanceiras.prever(tipo: "movimentacao_caixa", investidor: @investidor, usuario: @usuario, atributos: atributos_aporte)
    end
  end


  test "espaço arquivado fica somente leitura e pode ser restaurado" do
    @espaco.arquivar!
    assert_not EspacoPolicy.new(@usuario, @espaco).update?
    assert EspacoPolicy.new(@usuario, @espaco).restaurar?
    assert_not MembroEspacoPolicy.new(@usuario, @espaco.membros_espaco.first).update?
  end


  test "conta e moeda-base ficam imutáveis após fato confirmado mesmo sem lançamento" do
    atributos = atributos_nota(custo: "0").merge(negociacoes: [
      { ativo_id: @ativo.id, natureza: "compra", quantidade: "1", preco_unitario: "10" },
      { ativo_id: @ativo.id, natureza: "venda", quantidade: "1", preco_unitario: "10" }
    ])
    criar_e_confirmar("nota_negociacao", atributos)
    outra = @investidor.carteiras.create!(nome: "Outra", moeda_base: @brl)
    assert_not @conta.update(carteira: outra)
    assert_not @carteira.update(moeda_base: @usd)
  end

  test "filho não pode ser restaurado sob ancestral arquivado" do
    @investidor.arquivar!
    @carteira.arquivar!
    @carteira.reload

    assert_not CarteiraPolicy.new(@usuario, @carteira).restaurar?
    assert_raises(ActiveRecord::RecordInvalid) { @carteira.restaurar! }

    @espaco.arquivar!
    assert_not InvestidorPolicy.new(@usuario, @investidor).restaurar?
    assert_raises(ActiveRecord::RecordInvalid) { @investidor.restaurar! }
  end

  test "policies negam restauração de qualquer descendente sob espaço arquivado" do
    @carteira.arquivar!
    @conta.arquivar!
    @caixa_brl.arquivar!
    @espaco.arquivar!

    assert_not CarteiraPolicy.new(@usuario, @carteira).restaurar?
    assert_not ContaInvestimentoPolicy.new(@usuario, @conta).restaurar?
    assert_not ContaCaixaPolicy.new(@usuario, @caixa_brl).restaurar?
  end

  test "seed encontra administrador por email normalizado" do
    existente = User.create!(email: "seed-admin@example.com", password: "senha-antiga")
    anterior_email = ENV["ADMIN_EMAIL"]
    anterior_senha = ENV["ADMIN_PASSWORD"]
    ENV["ADMIN_EMAIL"] = " SEED-ADMIN@EXAMPLE.COM "
    ENV["ADMIN_PASSWORD"] = "senha-nova"

    assert_no_difference("User.count") { load Rails.root.join("db/seeds.rb") }
    assert existente.reload.administrador_sistema?
  ensure
    ENV["ADMIN_EMAIL"] = anterior_email
    ENV["ADMIN_PASSWORD"] = anterior_senha
  end
end
