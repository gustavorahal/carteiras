ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @brl = Moeda.create!(codigo: "BRL", nome: "Real", tipo: :fiduciaria, casas_decimais: 2)
    @usd = Moeda.create!(codigo: "USD", nome: "Dólar", tipo: :fiduciaria, casas_decimais: 2)
    @usuario = User.create!(email: "pessoa-#{SecureRandom.hex(4)}@example.com", password: "segredo123", role: :investidor)
    @investidor = Investidor.create!(user: @usuario, nome: "Pessoa", moeda_fiscal: @brl)
    @carteira = Carteira.create!(investidor: @investidor, nome: "Principal", moeda_base: @brl)
    @corretora = Corretora.create!(nome: "Corretora", pais: "BR")
    @conta = ContaInvestimento.create!(carteira: @carteira, corretora: @corretora, nome: "Conta 1")
    @caixa_brl = ContaCaixa.create!(conta_investimento: @conta, moeda: @brl)
    @ativo = Ativo.create!(codigo: "PETR4", mercado: "B3", descricao: "Petrobras", tipo: :acao,
      moeda_negociacao: @brl, moeda_exposicao: @brl)
  end

  def atributos_operacao(natureza:, quantidade:, preco:, data: Date.new(2026, 1, 10), custos: 0, conta: @conta, ativo: @ativo)
    {
      conta_investimento: conta, ativo:, natureza:, quantidade:, preco_unitario: preco,
      moeda: ativo.moeda_negociacao, data_negociacao: data, data_liquidacao: data + 2,
      taxa: custos, emolumentos: 0, corretagem: 0, iss_iof: 0, irrf: 0, outros: 0,
      taxa_conversao_base: 1, taxa_conversao_fiscal: 1
    }
  end

  def registrar_operacao(**opcoes)
    RegistrarOperacao.call(carteira: @carteira, usuario: @usuario,
      atributos: atributos_operacao(**opcoes))
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
