require "test_helper"

class AutorizacaoPropriedadeTest < ActiveSupport::TestCase
  test "investidor só enxerga a própria carteira e seus eventos" do
    outro_usuario = User.create!(email: "outro@example.com", password: "segredo123", role: :investidor)
    outro_investidor = Investidor.create!(user: outro_usuario, nome: "Outro", moeda_fiscal: @brl)
    outra_carteira = Carteira.create!(investidor: outro_investidor, nome: "Outra", moeda_base: @brl)
    evento = registrar_operacao(natureza: :compra, quantidade: 1, preco: 10)

    assert_equal [@carteira.id], Pundit.policy_scope!(@usuario, Carteira).pluck(:id)
    assert EventoFinanceiroPolicy.new(@usuario, evento).show?
    assert_not EventoFinanceiroPolicy.new(outro_usuario, evento).show?
    assert_not CarteiraPolicy.new(@usuario, outra_carteira).show?
  end

  test "referências publicadas são globais para leitura e administrativas para escrita" do
    referencia = Referencia.create!(nome: "Global")
    assert ReferenciaPolicy.new(@usuario, referencia).show?
    assert_not ReferenciaPolicy.new(@usuario, referencia).update?
    assert_equal [referencia.id], Pundit.policy_scope!(@usuario, Referencia).pluck(:id)
  end
end
