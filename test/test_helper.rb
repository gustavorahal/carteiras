ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    next if is_a?(ActionDispatch::IntegrationTest) || is_a?(ActionDispatch::SystemTestCase)

    @brl = Moeda.create!(codigo: "BRL", nome: "Real", casas_decimais: 2)
    @usd = Moeda.create!(codigo: "USD", nome: "Dólar", casas_decimais: 2)
    @fonte_manual = FonteCotacao.create!(codigo: "MANUAL", nome: "Manual")
    @fonte_yahoo = FonteCotacao.create!(codigo: "YAHOO", nome: "Yahoo Finance")
    @admin_sistema = User.create!(email: "admin-#{SecureRandom.hex(4)}@example.com", password: "segredo123", administrador_sistema: true)
    @usuario = User.create!(email: "editor-#{SecureRandom.hex(4)}@example.com", password: "segredo123")
    @leitor = User.create!(email: "leitor-#{SecureRandom.hex(4)}@example.com", password: "segredo123")
    @estranho = User.create!(email: "estranho-#{SecureRandom.hex(4)}@example.com", password: "segredo123")
    @espaco = Espaco.create!(nome: "Meu espaço")
    @espaco.membros_espaco.create!(user: @usuario, papel: "administrador")
    @espaco.membros_espaco.create!(user: @leitor, papel: "leitor")
    @investidor = @espaco.investidores.create!(nome: "Pessoa")
    @carteira = @investidor.carteiras.create!(nome: "Principal", moeda_base: @brl)
    @instituicao = Instituicao.create!(nome: "Instituição")
    @conta = @carteira.contas_investimento.create!(nome: "Conta 1", instituicao: @instituicao)
    @caixa_brl = @conta.contas_caixa.create!(moeda: @brl)
    @caixa_usd = @conta.contas_caixa.create!(moeda: @usd)
    @ativo = Ativo.create!(codigo: "PETR4", mercado: "B3", descricao: "Petrobras", tipo: "acao", moeda_negociacao: @brl, simbolo_yahoo: "PETR4.SA")
  end

  def atributos_aporte(valor: "1000.00", data: "2026-01-02", caixa: @caixa_brl)
    { tipo_movimentacao: "aporte", conta_caixa_destino_id: caixa.id, valor:, data_efetiva: data }
  end

  def atributos_nota(natureza: "compra", quantidade: "10", preco: "10", custo: "2", data: "2026-01-05", caixa: @caixa_brl, ativo: @ativo)
    { conta_caixa_id: caixa.id, data_negociacao: data, data_liquidacao: data,
      custo_operacional_total: custo, taxa_conversao_base: "1",
      negociacoes: [{ ativo_id: ativo.id, natureza:, quantidade:, preco_unitario: preco }] }
  end

  def criar_e_confirmar(tipo, atributos, usuario: @usuario)
    transacao = TransacoesFinanceiras.criar_rascunho(tipo:, investidor: @investidor, usuario:, atributos:)
    TransacoesFinanceiras.confirmar(transacao:, usuario:)
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
