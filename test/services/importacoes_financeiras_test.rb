require "test_helper"
require "tempfile"
require "minitest/mock"

class ImportacoesFinanceirasTest < ActiveSupport::TestCase
  XP_ATUAL = <<~TEXTO
    Nota de Negociação
    Data de Referência: 05/01/2026
    Conta XP 2540153
    Data pregão Nº Nota
     05/01/2026 123456789
       1-BOVESPA C VISTA PETROBRAS PETR4 ON NM 10 10,00 100,00 D
    Líquido para 07/01/2026 101,00 D
  TEXTO
  XP_ANTIGA = <<~TEXTO
    NOTA DE NEGOCIAÇÃO
    XP INVESTIMENTOS CCTVM S/A
    Nr. nota Folha Data pregão
      47135574 1 25/03/2022
    Cliente
      2540153 CLAUDIO
      1-BOVESPA V VISTA PETROBRAS PETR4 ON NM 10 10,00 100,00 C
    Líquido para 29/03/2022 99,00 C
  TEXTO
  AVENUE_ANTIGA = <<~TEXTO
    Avenue Securities
    Transaction Confirmation
    Account Number: AVSE-001 Account Name: Pessoa
    ARGT GLOBAL X ARGENTINA C Buy 2 10.00 1/3/2020 1/5/2020 Agent
    Principal Amount $20.00
    Commission or Equivalent $0.50
    Transaction Fee $0.00
    Other Fees / Credits $0.00
    Net Amount $20.50
    Clearing and Execution provided by DriveWealth LLC
  TEXTO
  AVENUE_ATUAL = <<~TEXTO
    Apex Clearing Corporation
    P.O. Box 9007
    Account Number: 6AS-38849
    1 B 12/03/25 12/04/25 2 ARGT 10.0000000 20.00 0.00 0.00 0.00 TAG 20.00 TRADE
  TEXTO

  test "detecta e extrai os quatro layouts de nota" do
    casos = [[XP_ATUAL, "xp_atual"], [XP_ANTIGA, "xp_antiga"],
      [AVENUE_ANTIGA, "avenue_drivewealth"], [AVENUE_ATUAL, "avenue_atual"]]
    casos.each do |texto, formato|
      adapter = ImportacoesFinanceiras::Interno.adapter_pdf(texto)
      dados = adapter.new(texto).extrair
      assert_equal formato, dados["formato"]
      assert_equal 1, dados.fetch("notas").size
      assert_equal 1, dados.fetch("notas").first.fetch("negociacoes").size
    end
  end

  test "Avenue preserva ticker com classe e compara líquido real com custos extraídos" do
    texto = AVENUE_ATUAL.sub("ARGT", "BRK.B").sub("TAG 20.00", "TAG 21.00")
    nota = ImportacoesFinanceiras::Adapters::AvenueAtual.new(texto).extrair.fetch("notas").first

    assert_equal "BRK.B", nota.fetch("negociacoes").first.fetch("ticker")
    assert_equal "-21.0", nota.fetch("liquido_informado")
    assert_equal "-20.0", nota.fetch("liquido_calculado")
    assert_equal "1.0", nota.fetch("diferenca")
  end

  test "pdf inválido persiste falha e checksum torna reenvio idempotente" do
    arquivo = Tempfile.new(["invalido", ".pdf"])
    arquivo.write("não é um PDF")
    arquivo.flush
    primeira = ImportacoesFinanceiras.analisar(arquivos: [arquivo], conta: @conta, usuario: @usuario).first
    segunda = ImportacoesFinanceiras.analisar(arquivos: [arquivo], conta: @conta, usuario: @usuario).first
    assert_equal primeira, segunda
    assert_equal "falhou", primeira.estado
    assert primeira.erro_resumido.present?
    assert_empty primeira.transacoes_financeiras
  ensure
    arquivo&.close!
  end

  test "arquivo sem transações é reanalisado depois de atualização do parser" do
    arquivo = Tempfile.new(["reprocessar", ".pdf"])
    arquivo.write("inválido")
    arquivo.flush
    importacao = ImportacoesFinanceiras.analisar(arquivos: [arquivo], conta: @conta, usuario: @usuario).first
    importacao.update!(versao_parser: "0")

    ImportacoesFinanceiras::Interno.stub(:extrair_texto_pdf, XP_ATUAL) do
      reanalisada = ImportacoesFinanceiras.analisar(arquivos: [arquivo], conta: @conta, usuario: @usuario).first
      assert_equal importacao, reanalisada
      assert_equal "analisada", reanalisada.estado
      assert_equal ImportacoesFinanceiras::VERSAO_PARSER, reanalisada.versao_parser
      assert_nil reanalisada.erro_resumido
    end
  ensure
    arquivo&.close!
  end

  test "conta externa divergente bloqueia criação de rascunhos" do
    @conta.update!(identificador_externo: "999999")
    arquivo = Tempfile.new(["conta-divergente", ".pdf"])
    arquivo.write("conteúdo substituído no teste")
    arquivo.flush

    ImportacoesFinanceiras::Interno.stub(:extrair_texto_pdf, XP_ATUAL) do
      importacao = ImportacoesFinanceiras.analisar(arquivos: [arquivo], conta: @conta, usuario: @usuario).first
      assert_includes importacao.pendencias.pluck("campo"), "nota.0.conta_externa"
      assert_raises(Financeiro::AtributosInvalidos) do
        ImportacoesFinanceiras.criar_rascunhos(importacao:, usuario: @usuario, resolucoes: {})
      end
      assert_empty importacao.transacoes_financeiras
    end
  ensure
    arquivo&.close!
  end

  test "upload limita quantidade de arquivos por requisição" do
    arquivo = Tempfile.new(["nota", ".pdf"])
    arquivo.write("x")
    arquivo.flush
    assert_raises(Financeiro::AtributosInvalidos) do
      ImportacoesFinanceiras.analisar(arquivos: Array.new(21, arquivo), conta: @conta, usuario: @usuario)
    end
    assert_equal 0, ImportacaoFinanceira.count
  ensure
    arquivo&.close!
  end

  test "upload resolução rascunho prévia confirmação e posição" do
    arquivo = Tempfile.new(["nota", ".pdf"])
    arquivo.write("conteúdo substituído no teste")
    arquivo.flush
    ImportacoesFinanceiras::Interno.stub(:extrair_texto_pdf, XP_ATUAL) do
      importacao = ImportacoesFinanceiras.analisar(arquivos: [arquivo], conta: @conta, usuario: @usuario).first
      assert_equal "analisada", importacao.estado
      assert_empty importacao.pendencias
      rascunhos = ImportacoesFinanceiras.criar_rascunhos(importacao:, usuario: @usuario, resolucoes: {})
      assert_equal 1, rascunhos.size
      rascunho = rascunhos.first
      assert_equal "importacao", rascunho.origem
      assert_equal importacao, rascunho.importacao_financeira
      previa = TransacoesFinanceiras.prever(tipo: rascunho.tipo, investidor: @investidor, usuario: @usuario,
        atributos: { conta_caixa_id: @caixa_brl.id, data_negociacao: "2026-01-05", data_liquidacao: "2026-01-07",
          custo_operacional_total: "1", taxa_conversao_base: "1",
          negociacoes: [{ ativo_id: @ativo.id, natureza: "compra", quantidade: "10", preco_unitario: "10" }] })
      assert_equal BigDecimal("10"), previa.posicoes_resultantes.first[:quantidade]
      ImportacoesFinanceiras.confirmar_em_lote(importacoes: [importacao], usuario: @usuario)
      assert_equal BigDecimal("10"), PosicaoAtual.find_by!(ativo: @ativo).quantidade
    end
  ensure
    arquivo&.close!
  end

  test "ticker desconhecido e câmbio ausente permanecem pendentes" do
    arquivo = Tempfile.new(["avenue", ".pdf"])
    arquivo.write("conteúdo substituído no teste")
    arquivo.flush
    ImportacoesFinanceiras::Interno.stub(:extrair_texto_pdf, AVENUE_ATUAL.sub("ARGT", "ZZZZ")) do
      importacao = ImportacoesFinanceiras.analisar(arquivos: [arquivo], conta: @conta, usuario: @usuario).first
      campos = importacao.pendencias.pluck("campo")
      assert_includes campos, "nota.0.negociacao.0.ativo_id"
      assert_includes campos, "nota.0.taxa_conversao_base"
      assert_raises(Financeiro::AtributosInvalidos) do
        ImportacoesFinanceiras.criar_rascunhos(importacao:, usuario: @usuario, resolucoes: {})
      end
      assert_empty importacao.transacoes_financeiras
    end
  ensure
    arquivo&.close!
  end

  test "nota estrangeira sugere última cotação até a liquidação" do
    argt = Ativo.create!(codigo: "ARGT", mercado: "EUA", tipo: "etf", moeda_negociacao: @usd)
    Mercado.registrar_cotacao_cambio(moeda_origem: @usd, moeda_destino: @brl, data: "2025-12-01",
      taxa: "5.25", usuario: @admin_sistema)
    arquivo = Tempfile.new(["avenue", ".pdf"])
    arquivo.write("conteúdo substituído no teste")
    arquivo.flush
    ImportacoesFinanceiras::Interno.stub(:extrair_texto_pdf, AVENUE_ATUAL) do
      importacao = ImportacoesFinanceiras.analisar(arquivos: [arquivo], conta: @conta, usuario: @usuario).first
      nota = importacao.dados_extraidos.fetch("notas").first
      assert_equal "5.25", nota["taxa_conversao_base"]
      rascunho = ImportacoesFinanceiras.criar_rascunhos(importacao:, usuario: @usuario, resolucoes: {}).first
      assert_equal argt, rascunho.nota_negociacao.negociacoes.first.ativo
      assert_equal BigDecimal("5.25"), rascunho.nota_negociacao.taxa_conversao_base
    end
  ensure
    arquivo&.close!
  end

  test "extrato vincula liquidação existente e cria só aporte inequívoco como rascunho" do
    criar_e_confirmar("movimentacao_caixa", atributos_aporte(valor: "100", data: "2026-01-10"))
    arquivo = Tempfile.new(["avenue", ".csv"])
    arquivo.write("Data;Hora;Liquidação;Descrição;Valor;Saldo\n")
    arquivo.write("2026-01-10;10:00;2026-01-10;Liquidação da nota;R$ 100,00;R$ 100,00\n")
    arquivo.write("2026-01-11;10:00;2026-01-11;Depósito recebido;R$ 200,00;R$ 300,00\n")
    arquivo.flush

    importacao = ImportacoesFinanceiras.analisar(arquivos: [arquivo], conta: @conta, usuario: @usuario).first
    assert_difference("TransacaoFinanceira.count", 1) do
      ImportacoesFinanceiras.criar_rascunhos(importacao:, usuario: @usuario, resolucoes: {})
    end
    itens = importacao.reload.dados_extraidos.fetch("itens")
    assert_equal "conciliado", itens.first["estado_conciliacao"]
    assert itens.first["lancamento_caixa_id"].present?
    assert_equal "rascunho_criado", itens.last["estado_conciliacao"]
    assert_equal "concluida", importacao.estado
    assert_equal "aporte", importacao.transacoes_financeiras.last.movimentacao_caixa.tipo
  ensure
    arquivo&.close!
  end

  test "item de extrato sem correspondência inequívoca permanece pendente" do
    arquivo = Tempfile.new(["avenue", ".csv"])
    arquivo.write("Data;Hora;Liquidação;Descrição;Valor;Saldo\n")
    arquivo.write("2026-01-10;10:00;2026-01-10;Ajuste não identificado;R$ 10,00;R$ 10,00\n")
    arquivo.flush
    importacao = ImportacoesFinanceiras.analisar(arquivos: [arquivo], conta: @conta, usuario: @usuario).first
    assert_no_difference("TransacaoFinanceira.count") do
      ImportacoesFinanceiras.criar_rascunhos(importacao:, usuario: @usuario, resolucoes: {})
    end
    assert_equal "analisada", importacao.reload.estado
    assert_equal "ambiguo", importacao.dados_extraidos.fetch("itens").first["estado_conciliacao"]
    assert importacao.pendencias.any?
  ensure
    arquivo&.close!
  end

  test "conciliação entrega diferenças de caixa e quantidade sem cálculo no caller" do
    criar_e_confirmar("saldo_inicial", { conta_investimento_id: @conta.id, ativo_id: @ativo.id,
      quantidade: "10", custo_total_local: "100", custo_total_base: "100", data_efetiva: "2026-01-01" })
    criar_e_confirmar("saldo_inicial_caixa", { conta_caixa_id: @caixa_brl.id,
      valor: "100", data_efetiva: "2026-01-01" })
    importacao = @conta.importacoes_financeiras.create!(investidor: @investidor, autor: @usuario,
      nome_original: "extrato.csv", checksum_sha256: "conciliacao", formato: "extrato_xp",
      versao_parser: ImportacoesFinanceiras::VERSAO_PARSER, estado: "analisada", dados_extraidos: {
        "itens" => [{ "moeda" => "BRL", "data_liquidacao" => "2026-01-31", "saldo_informado" => "80" }],
        "posicoes_informadas" => [{ "ativo_id" => @ativo.id, "quantidade" => "8" }]
      })

    conciliacao = ImportacoesFinanceiras.conciliacao(importacao:, usuario: @leitor)

    assert_equal BigDecimal("20"), conciliacao.saldos.first[:diferenca]
    assert_equal BigDecimal("2"), conciliacao.posicoes.first[:diferenca]
    assert_equal "PETR4", conciliacao.posicoes.first[:ativo]
  end
end
