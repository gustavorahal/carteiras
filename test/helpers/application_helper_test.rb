require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "formata números datas moedas e percentuais para pt-BR" do
    assert_equal "1.234,5", display_numero(BigDecimal("1234.5"))
    assert_equal "31/01/2026", display_data(Date.new(2026, 1, 31))
    assert_equal "R$ 1.234,50", strip_tags(display_moeda(BigDecimal("1234.5")))
    assert_equal "12,34%", strip_tags(display_porcentagem(BigDecimal("0.1234"), fracao: true))
    assert_equal "—", display_numero(nil)
  end

  test "traduz tipos estados e motivos financeiros" do
    assert_equal "Nota de negociação", display_tipo("nota_negociacao")
    assert_equal "Dados incompletos", display_estado("incompleto")
    assert_match(/cotações/, display_motivo("cotacao_ausente"))
    assert_includes status_badge("confirmada"), "Confirmada"
  end

  test "gráfico exige dois pontos calculáveis e produz svg acessível" do
    pontos = [
      { data: Date.new(2026, 1, 1), patrimonio_final: BigDecimal("100"), estado: "calculado" },
      { data: Date.new(2026, 1, 2), patrimonio_final: BigDecimal("105"), estado: "calculado" }
    ]
    grafico = portfolio_chart(pontos)
    assert_includes grafico, "<svg"
    assert_includes grafico, "Evolução do patrimônio"
    assert_nil portfolio_chart(pontos.first(1))
  end
end
