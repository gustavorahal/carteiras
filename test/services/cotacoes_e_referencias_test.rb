require "test_helper"

class CotacoesEReferenciasTest < ActiveSupport::TestCase
  test "seleciona primeira fonte ativa com preço e persiste somente a canônica" do
    primeira = FonteCotacao.create!(nome: "Primeira", prioridade: 1, tipos_atendidos: ["ativo"])
    segunda = FonteCotacao.create!(nome: "Segunda", prioridade: 2, tipos_atendidos: ["ativo"])
    chamadas = []
    SelecionarCotacao.ativo(ativo: @ativo, data: Date.current, buscadores: {
      primeira.nome => ->(*) { chamadas << :primeira; nil },
      segunda.nome => ->(*) { chamadas << :segunda; 12.34.to_d }
    })
    cotacao = CotacaoAtivo.find_by!(ativo: @ativo, data: Date.current)
    assert_equal 12.34.to_d, cotacao.preco
    assert_equal segunda, cotacao.fonte_cotacao
    assert_equal %i[primeira segunda], chamadas
    assert_equal 1, CotacaoAtivo.count
  end

  test "publicação exige exatamente cem por cento e torna versão imutável" do
    referencia = Referencia.create!(nome: "Moderada")
    versao = referencia.versoes.create!(vigencia_inicial: Date.new(2026, 1, 1))
    versao.alocacoes.create!(ativo: @ativo, categoria: "Ações", percentual: 100)
    PublicarVersaoReferencia.call(versao)
    assert versao.reload.publicada?
    assert_not versao.update(vigencia_inicial: Date.new(2026, 2, 1))
    assert_not versao.alocacoes.first.update(percentual: 90)
    assert_equal versao, referencia.versao_vigente_em(Date.new(2026, 6, 1))
  end

  test "publicação rejeita soma diferente de cem" do
    referencia = Referencia.create!(nome: "Incompleta")
    versao = referencia.versoes.create!(vigencia_inicial: Date.current)
    versao.alocacoes.create!(ativo: @ativo, categoria: "Ações", percentual: 99)
    assert_raises(ArgumentError) { PublicarVersaoReferencia.call(versao) }
    assert versao.reload.rascunho?
  end

  test "nova publicação preserva vigência e imutabilidade da versão encerrada" do
    referencia = Referencia.create!(nome: "Histórica")
    antiga = referencia.versoes.create!(vigencia_inicial: Date.new(2026, 1, 1))
    antiga.alocacoes.create!(ativo: @ativo, categoria: "Ações", percentual: 100)
    PublicarVersaoReferencia.call(antiga)
    nova = referencia.versoes.create!(vigencia_inicial: Date.new(2026, 7, 1))
    nova.alocacoes.create!(ativo: @ativo, categoria: "Ações", percentual: 100)
    PublicarVersaoReferencia.call(nova)

    assert antiga.reload.encerrada?
    assert_equal antiga, referencia.versao_vigente_em(Date.new(2026, 3, 1))
    assert_equal nova, referencia.versao_vigente_em(Date.new(2026, 8, 1))
    assert_not antiga.update(vigencia_inicial: Date.new(2025, 1, 1))
    assert_not antiga.alocacoes.create(ativo: Ativo.create!(codigo: "VALE3", mercado: "B3",
      tipo: :acao, moeda_negociacao: @brl, moeda_exposicao: @brl),
      categoria: "Ações", percentual: 0).persisted?
  end
end
