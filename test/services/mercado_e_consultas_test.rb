require "test_helper"
require "minitest/mock"

class MercadoEConsultasTest < ActiveSupport::TestCase
  test "cotação manual canônica bloqueia automação até liberação explícita" do
    manual = Mercado.registrar_cotacao_ativo(ativo: @ativo, data: "2026-01-05", preco: "10.50",
      fonte: @fonte_manual, manual: true, usuario: @admin_sistema)
    assert_equal "criada", manual.estado
    ignorada = Mercado.registrar_cotacao_ativo(ativo: @ativo, data: "2026-01-05", preco: "11",
      fonte: @fonte_brapi, manual: false)
    assert_equal "ignorada_manual", ignorada.estado
    assert_equal BigDecimal("10.5"), manual.cotacao.reload.preco
    Mercado.liberar_automacao(cotacao_ativo: manual.cotacao, usuario: @admin_sistema)
    atualizada = Mercado.registrar_cotacao_ativo(ativo: @ativo, data: "2026-01-05", preco: "11",
      fonte: @fonte_brapi, manual: false)
    assert_equal "atualizada", atualizada.estado
    assert_equal BigDecimal("11"), atualizada.cotacao.preco
  end

  test "somente administrador do sistema registra cotações manuais" do
    assert_raises(Financeiro::NaoAutorizado) do
      Mercado.registrar_cotacao_ativo(ativo: @ativo, data: "2026-01-05", preco: "10",
        fonte: @fonte_manual, manual: true, usuario: @usuario)
    end
    resultado = Mercado.registrar_cotacao_cambio(moeda_origem: @usd, moeda_destino: @brl,
      data: "2026-01-05", taxa: "5", usuario: @admin_sistema)
    assert_equal "criada", resultado.estado
  end

  test "posição histórica respeita liquidação e usa preço e câmbio defasados" do
    criar_e_confirmar("nota_negociacao", atributos_nota(data: "2026-01-05"))
    Mercado.registrar_cotacao_ativo(ativo: @ativo, data: "2026-01-05", preco: "12",
      fonte: @fonte_manual, manual: true, usuario: @admin_sistema)
    antes = ConsultasFinanceiras.posicao_historica(carteira: @carteira, data: Date.new(2026, 1, 4), usuario: @usuario)
    assert_empty antes.itens
    depois = ConsultasFinanceiras.posicao_historica(carteira: @carteira, data: Date.new(2026, 1, 7), usuario: @usuario)
    assert depois.completo
    assert_equal BigDecimal("120"), depois.valor_total_base
    assert_equal 2, depois.itens.first[:defasagem_preco]
    assert_equal "Petrobras", depois.itens.first[:ativo_descricao]
    assert_equal "Instituição", depois.itens.first[:instituicao]
  end

  test "variação da cotação independe do custo e exige duas observações" do
    criar_e_confirmar("saldo_inicial", { conta_investimento_id: @conta.id, ativo_id: @ativo.id,
      quantidade: "10", custo_desconhecido: "1", data_efetiva: "2026-01-01" })
    Mercado.registrar_cotacao_ativo(ativo: @ativo, data: "2026-01-01", preco: "10",
      fonte: @fonte_manual, manual: true, usuario: @admin_sistema)
    Mercado.registrar_cotacao_ativo(ativo: @ativo, data: "2026-01-31", preco: "12",
      fonte: @fonte_manual, manual: true, usuario: @admin_sistema)

    variacoes = ConsultasFinanceiras.variacoes_cotacao(carteira: @carteira,
      inicio: Date.new(2026, 1, 1), fim: Date.new(2026, 1, 31), ativo_ids: [@ativo.id], usuario: @usuario)
    assert_equal BigDecimal("0.2"), variacoes.itens.first[:variacao]
    assert_equal Date.new(2026, 1, 1), variacoes.itens.first[:data_inicial]
    assert_equal Date.new(2026, 1, 31), variacoes.itens.first[:data_final]

    indisponivel = ConsultasFinanceiras.variacoes_cotacao(carteira: @carteira,
      inicio: Date.new(2026, 1, 31), fim: Date.new(2026, 2, 1), ativo_ids: [@ativo.id], usuario: @usuario)
    assert_nil indisponivel.itens.first[:variacao]
  end

  test "saldo usa câmbio inverso sem triangular" do
    criar_e_confirmar("movimentacao_caixa", atributos_aporte(valor: "100", caixa: @caixa_usd))
    Mercado.registrar_cotacao_cambio(moeda_origem: @brl, moeda_destino: @usd,
      data: "2026-01-02", taxa: "0.2", usuario: @admin_sistema)
    saldos = ConsultasFinanceiras.saldos_caixa(carteira: @carteira, data: Date.new(2026, 1, 2), usuario: @usuario)
    assert saldos.completo
    assert_equal BigDecimal("500"), saldos.valor_total_base
    assert_equal BigDecimal("5"), saldos.itens.first[:taxa_cambio]
  end

  test "totais por corretora combinam posições e caixa" do
    criar_e_confirmar("saldo_inicial", { conta_investimento_id: @conta.id, ativo_id: @ativo.id,
      quantidade: "10", custo_total_local: "100", custo_total_base: "100", data_efetiva: "2026-01-01" })
    criar_e_confirmar("saldo_inicial_caixa", { conta_caixa_id: @caixa_brl.id,
      valor: "50", data_efetiva: "2026-01-01" })
    Mercado.registrar_cotacao_ativo(ativo: @ativo, data: "2026-01-01", preco: "12",
      fonte: @fonte_manual, manual: true, usuario: @admin_sistema)

    posicao = ConsultasFinanceiras.posicao_historica(carteira: @carteira,
      data: Date.new(2026, 1, 1), usuario: @usuario)
    saldos = ConsultasFinanceiras.saldos_caixa(carteira: @carteira,
      data: Date.new(2026, 1, 1), usuario: @usuario)
    totais = ConsultasFinanceiras.totais_por_corretora(posicao:, saldos:)

    assert_equal 1, totais.itens.size
    assert_equal "Instituição", totais.itens.first[:instituicao]
    assert_equal BigDecimal("120"), totais.itens.first[:ativos]
    assert_equal BigDecimal("50"), totais.itens.first[:caixa]
    assert_equal BigDecimal("170"), totais.itens.first[:total]
  end

  test "totais por categoria agregam ativos e explicitam os não classificados" do
    outro = Ativo.create!(codigo: "GOLD11", mercado: "B3", tipo: "etf", moeda_negociacao: @brl)
    @carteira.classificacoes_ativos.create!(ativo: outro, categoria: "commodities")
    criar_e_confirmar("saldo_inicial", { conta_investimento_id: @conta.id, ativo_id: @ativo.id,
      quantidade: "10", custo_total_local: "100", custo_total_base: "100", data_efetiva: "2026-01-01" })
    criar_e_confirmar("saldo_inicial", { conta_investimento_id: @conta.id, ativo_id: outro.id,
      quantidade: "2", custo_total_local: "100", custo_total_base: "100", data_efetiva: "2026-01-01" })
    Mercado.registrar_cotacao_ativo(ativo: @ativo, data: "2026-01-01", preco: "10",
      fonte: @fonte_manual, manual: true, usuario: @admin_sistema)
    Mercado.registrar_cotacao_ativo(ativo: outro, data: "2026-01-01", preco: "50",
      fonte: @fonte_manual, manual: true, usuario: @admin_sistema)

    posicao = ConsultasFinanceiras.posicao_historica(carteira: @carteira,
      data: Date.new(2026, 1, 1), usuario: @usuario)
    totais = ConsultasFinanceiras.totais_por_categoria(posicao:, patrimonio_total: posicao.valor_total_base)

    assert_equal ["commodities", "nao_classificado"], totais.itens.pluck(:categoria)
    assert_equal BigDecimal("100"), totais.itens.first[:valor]
    assert_equal BigDecimal("0.5"), totais.itens.first[:percentual]
    assert_equal "Não classificado", totais.itens.last[:categoria_descricao]
    assert_equal BigDecimal("200"), totais.valor_total_base
  end

  test "composição entrega patrimônio preço médio e participações com caixa no denominador" do
    @carteira.classificacoes_ativos.create!(ativo: @ativo, categoria: "acoes")
    criar_e_confirmar("saldo_inicial", { conta_investimento_id: @conta.id, ativo_id: @ativo.id,
      quantidade: "10", custo_total_local: "100", custo_total_base: "100", data_efetiva: "2026-01-01" })
    criar_e_confirmar("saldo_inicial_caixa", { conta_caixa_id: @caixa_brl.id,
      valor: "30", data_efetiva: "2026-01-01" })
    Mercado.registrar_cotacao_ativo(ativo: @ativo, data: "2026-01-01", preco: "12",
      fonte: @fonte_manual, manual: true, usuario: @admin_sistema)

    composicao = ConsultasFinanceiras.composicao(carteira: @carteira,
      data: Date.new(2026, 1, 1), usuario: @usuario)
    item = composicao.posicao.itens.first

    assert composicao.completo
    assert_equal BigDecimal("150"), composicao.patrimonio_total_base
    assert_equal BigDecimal("10"), item[:preco_medio_local]
    assert_equal BigDecimal("0.8"), item[:participacao_carteira]
    assert_equal BigDecimal("0.8"), composicao.totais_por_categoria.itens.first[:percentual]
    assert_equal item, composicao.grupos_posicoes.first[:itens].first
  end

  test "resultados realizados são derivados por custo médio e consulta não grava" do
    criar_e_confirmar("nota_negociacao", atributos_nota(quantidade: "10", preco: "10", custo: "0"))
    criar_e_confirmar("nota_negociacao", atributos_nota(natureza: "venda", quantidade: "4", preco: "15", custo: "2", data: "2026-01-06"))
    antes = [TransacaoFinanceira.count, PosicaoAtual.count, LancamentoCaixa.count]
    resultados = ConsultasFinanceiras.resultados_realizados(carteira: @carteira,
      inicio: Date.new(2026, 1, 1), fim: Date.new(2026, 1, 31), usuario: @usuario)
    assert_equal BigDecimal("18"), resultados.total_base
    assert_equal antes, [TransacaoFinanceira.count, PosicaoAtual.count, LancamentoCaixa.count]
  end

  test "TWR produz um ponto por dia civil e encadeia dias sem movimento" do
    criar_e_confirmar("movimentacao_caixa", atributos_aporte(valor: "100", data: "2026-01-01"))
    rentabilidade = ConsultasFinanceiras.rentabilidade(carteira: @carteira,
      inicio: Date.new(2026, 1, 2), fim: Date.new(2026, 1, 4), usuario: @usuario)
    assert rentabilidade.completo
    assert_equal 3, rentabilidade.pontos.size
    assert_equal [BigDecimal("0"), BigDecimal("0"), BigDecimal("0")], rentabilidade.pontos.pluck(:twr_diario)
    assert_equal BigDecimal("0"), rentabilidade.twr_acumulado
  end

  test "TWR começa no dia seguinte ao saldo inicial" do
    Mercado.registrar_cotacao_ativo(ativo: @ativo, data: "2026-01-01", preco: "10",
      fonte: @fonte_manual, usuario: @admin_sistema, manual: true)
    Mercado.registrar_cotacao_ativo(ativo: @ativo, data: "2026-01-02", preco: "10",
      fonte: @fonte_manual, usuario: @admin_sistema, manual: true)
    criar_e_confirmar("saldo_inicial", { conta_investimento_id: @conta.id, ativo_id: @ativo.id,
      quantidade: "10", custo_total_local: "80", custo_total_base: "80", data_efetiva: "2026-01-01" })

    no_corte = ConsultasFinanceiras.rentabilidade(carteira: @carteira,
      inicio: Date.new(2026, 1, 1), fim: Date.new(2026, 1, 1), usuario: @usuario)
    assert_equal BigDecimal("100"), no_corte.pontos.first[:fluxo_externo_liquido]
    assert_equal "corte_saldo_inicial", no_corte.pontos.first[:estado]

    depois = ConsultasFinanceiras.rentabilidade(carteira: @carteira,
      inicio: Date.new(2026, 1, 2), fim: Date.new(2026, 1, 2), usuario: @usuario)
    assert depois.completo
    assert_equal BigDecimal("0"), depois.twr_acumulado
  end

  test "TWR começa no dia seguinte ao saldo inicial de caixa" do
    criar_e_confirmar("saldo_inicial_caixa", { conta_caixa_id: @caixa_brl.id,
      valor: "100", data_efetiva: "2026-01-01" })

    no_corte = ConsultasFinanceiras.rentabilidade(carteira: @carteira,
      inicio: Date.new(2026, 1, 1), fim: Date.new(2026, 1, 1), usuario: @usuario)
    assert_equal BigDecimal("100"), no_corte.pontos.first[:fluxo_externo_liquido]
    assert_equal "corte_saldo_inicial", no_corte.pontos.first[:estado]

    depois = ConsultasFinanceiras.rentabilidade(carteira: @carteira,
      inicio: Date.new(2026, 1, 2), fim: Date.new(2026, 1, 2), usuario: @usuario)
    assert depois.completo
    assert_equal BigDecimal("0"), depois.twr_acumulado
  end

  test "TWR reinicia no dia seguinte ao saldo inicial mesmo com patrimônio anterior" do
    criar_e_confirmar("movimentacao_caixa", atributos_aporte(valor: "100", data: "2025-12-31"))
    %w[2026-01-02 2026-01-03].each do |data|
      Mercado.registrar_cotacao_ativo(ativo: @ativo, data:, preco: "10",
        fonte: @fonte_manual, usuario: @admin_sistema, manual: true)
    end
    criar_e_confirmar("saldo_inicial", { conta_investimento_id: @conta.id, ativo_id: @ativo.id,
      quantidade: "10", custo_total_local: "80", custo_total_base: "80", data_efetiva: "2026-01-02" })

    rentabilidade = ConsultasFinanceiras.rentabilidade(carteira: @carteira,
      inicio: Date.new(2026, 1, 2), fim: Date.new(2026, 1, 3), usuario: @usuario)
    assert_equal "corte_saldo_inicial", rentabilidade.pontos.first[:estado]
    assert_nil rentabilidade.pontos.first[:twr_diario]
    assert_equal "calculado", rentabilidade.pontos.last[:estado]
    assert_equal BigDecimal("0"), rentabilidade.pontos.last[:twr_acumulado]
  end

  test "transferência de custódia interna não é fluxo e entre carteiras é externa" do
    outra_conta = @carteira.contas_investimento.create!(nome: "Conta interna", instituicao: @instituicao)
    outra_carteira = @investidor.carteiras.create!(nome: "Outra carteira", moeda_base: @brl)
    conta_externa = outra_carteira.contas_investimento.create!(nome: "Conta externa", instituicao: @instituicao)
    %w[2026-01-01 2026-01-02 2026-01-03].each do |data|
      Mercado.registrar_cotacao_ativo(ativo: @ativo, data:, preco: "10",
        fonte: @fonte_manual, usuario: @admin_sistema, manual: true)
    end
    criar_e_confirmar("saldo_inicial", { conta_investimento_id: @conta.id, ativo_id: @ativo.id,
      quantidade: "10", custo_total_local: "100", custo_total_base: "100", data_efetiva: "2026-01-01" })
    criar_e_confirmar("transferencia_custodia", { conta_origem_id: @conta.id, conta_destino_id: outra_conta.id,
      ativo_id: @ativo.id, quantidade: "4", data_efetiva: "2026-01-02" })
    criar_e_confirmar("transferencia_custodia", { conta_origem_id: @conta.id, conta_destino_id: conta_externa.id,
      ativo_id: @ativo.id, quantidade: "3", data_efetiva: "2026-01-03" })

    rentabilidade = ConsultasFinanceiras.rentabilidade(carteira: @carteira,
      inicio: Date.new(2026, 1, 2), fim: Date.new(2026, 1, 3), usuario: @usuario)
    assert_equal BigDecimal("0"), rentabilidade.pontos.first[:fluxo_externo_liquido]
    assert_equal BigDecimal("-30"), rentabilidade.pontos.last[:fluxo_externo_liquido]
    assert_equal BigDecimal("0"), rentabilidade.twr_acumulado
  end

  test "carteira vazia não reporta retorno zero" do
    rentabilidade = ConsultasFinanceiras.rentabilidade(carteira: @carteira,
      inicio: Date.new(2026, 1, 2), fim: Date.new(2026, 1, 2), usuario: @usuario)
    assert_not rentabilidade.completo
    assert_nil rentabilidade.twr_acumulado
    assert_equal "sem_patrimonio_inicial_valido", rentabilidade.pontos.first[:estado]
  end


  test "ausência de preço torna posição incompleta sem gravar projeções" do
    criar_e_confirmar("nota_negociacao", atributos_nota)
    posicao = ConsultasFinanceiras.posicao_historica(carteira: @carteira, data: Date.new(2026, 1, 5), usuario: @usuario)
    assert_not posicao.completo
    assert_nil posicao.valor_total_base
    assert_nil posicao.itens.first[:preco]
  end

  test "correção de cotação aparece na consulta seguinte" do
    criar_e_confirmar("nota_negociacao", atributos_nota)
    Mercado.registrar_cotacao_ativo(ativo: @ativo, data: "2026-01-05", preco: "10",
      fonte: @fonte_manual, manual: true, usuario: @admin_sistema)
    primeira = ConsultasFinanceiras.posicao_historica(carteira: @carteira, data: Date.new(2026, 1, 5), usuario: @usuario)
    Mercado.registrar_cotacao_ativo(ativo: @ativo, data: "2026-01-05", preco: "12",
      fonte: @fonte_manual, manual: true, usuario: @admin_sistema)
    segunda = ConsultasFinanceiras.posicao_historica(carteira: @carteira, data: Date.new(2026, 1, 5), usuario: @usuario)
    assert_equal BigDecimal("100"), primeira.valor_total_base
    assert_equal BigDecimal("120"), segunda.valor_total_base
  end


  test "posição atual mantém quantidade constante de consultas ao crescer" do
    criar_e_confirmar("nota_negociacao", atributos_nota)
    Mercado.registrar_cotacao_ativo(ativo: @ativo, data: Date.current, preco: "10",
      fonte: @fonte_manual, manual: true, usuario: @admin_sistema)
    pequeno = contar_consultas { ConsultasFinanceiras.posicao_atual(carteira: @carteira, usuario: @usuario) }
    outro = Ativo.create!(codigo: "VALE3", mercado: "B3", tipo: "acao", moeda_negociacao: @brl)
    criar_e_confirmar("nota_negociacao", atributos_nota(ativo: outro))
    Mercado.registrar_cotacao_ativo(ativo: outro, data: Date.current, preco: "10",
      fonte: @fonte_manual, manual: true, usuario: @admin_sistema)
    grande = contar_consultas { ConsultasFinanceiras.posicao_atual(carteira: @carteira, usuario: @usuario) }
    assert_equal pequeno, grande
  end

  test "TWR de trinta e 365 dias mantém quantidade constante de consultas" do
    criar_e_confirmar("movimentacao_caixa", atributos_aporte(valor: "100", data: "2025-01-01"))
    @carteira.reload
    @usuario.reload
    curto = contar_consultas do
      ConsultasFinanceiras.rentabilidade(carteira: @carteira, inicio: Date.new(2025, 1, 2),
        fim: Date.new(2025, 1, 31), usuario: @usuario)
    end
    @carteira.reload
    @usuario.reload
    longo = contar_consultas do
      ConsultasFinanceiras.rentabilidade(carteira: @carteira, inicio: Date.new(2025, 1, 2),
        fim: Date.new(2026, 1, 1), usuario: @usuario)
    end
    assert_equal curto, longo
  end

  test "replay em lote não cresce consultas com a quantidade de notas" do
    criar_e_confirmar("nota_negociacao", atributos_nota)
    pequeno = contar_consultas { TransacoesFinanceiras::Interno.eventos_confirmados(@investidor.reload) }
    criar_e_confirmar("nota_negociacao", atributos_nota(data: "2026-01-06"))
    grande = contar_consultas { TransacoesFinanceiras::Interno.eventos_confirmados(@investidor.reload) }

    assert_equal pequeno, grande
  end

  test "falha brapi preserva valor e não impede os ativos posteriores" do
    outro = Ativo.create!(codigo: "VALE3", mercado: "B3", tipo: "acao", moeda_negociacao: @brl)
    data = Date.new(2026, 1, 5)
    existente = Mercado.registrar_cotacao_ativo(ativo: @ativo, data:, preco: "9", fonte: @fonte_brapi, manual: false).cotacao
    buscador = lambda do |simbolo, _data, token:|
      assert_equal "token-teste", token
      raise Net::ReadTimeout, "timeout de teste" if simbolo == @ativo.codigo
      BigDecimal("20")
    end

    assert_raises(RuntimeError) do
      Mercado::Interno.stub(:token_brapi!, "token-teste") do
        Mercado::Interno.stub(:buscar_brapi, buscador) { Mercado.buscar_e_registrar_brapi(data:) }
      end
    end
    assert_equal BigDecimal("9"), existente.reload.preco
    assert_equal BigDecimal("20"), CotacaoAtivo.find_by!(ativo: outro, data:).preco
  end

  test "cliente brapi autentica e seleciona somente a cotação da data solicitada" do
    data = Date.new(2026, 1, 5)
    anterior = Time.find_zone!("Brasilia").local(2026, 1, 2).to_i
    exato = Time.find_zone!("Brasilia").local(2026, 1, 5).to_i
    resposta = resposta_http(Net::HTTPOK, {
      results: [{ requestedSymbol: "PETR4", data: { historicalDataPrice: [
        { date: anterior, close: 9 }, { date: exato, close: 12.34 }
      ] } }]
    }.to_json)
    cliente = Object.new
    cliente.define_singleton_method(:request) do |uri, requisicao|
      raise "consulta sem data exata" unless uri.query.include?("startDate=2026-01-05") && uri.query.include?("endDate=2026-01-05")
      raise "token ausente" unless requisicao["Authorization"] == "Bearer segredo"
      resposta
    end

    assert_equal BigDecimal("12.34"), Mercado::Interno.buscar_brapi("PETR4", data, token: "segredo", http: cliente)
  end

  test "cliente brapi trata dia sem pregão sem falhar" do
    resposta = resposta_http(Net::HTTPNotFound, { error: true, code: "NOT_FOUND" }.to_json)
    cliente = Object.new
    cliente.define_singleton_method(:request) { |_uri, _requisicao| resposta }

    assert_nil Mercado::Interno.buscar_brapi("PETR4", Date.new(2026, 1, 4), token: "segredo", http: cliente)
  end

  test "cliente brapi trata timeout e resposta inválida como falhas" do
    timeout = Object.new
    timeout.define_singleton_method(:request) { |_uri, _requisicao| raise Net::ReadTimeout, "timeout" }
    assert_raises(Net::ReadTimeout) { Mercado::Interno.buscar_brapi("PETR4", Date.current, token: "segredo", http: timeout) }

    resposta = resposta_http(Net::HTTPOK, "não é json")
    invalido = Object.new
    invalido.define_singleton_method(:request) { |_uri, _requisicao| resposta }
    erro = assert_raises(RuntimeError) { Mercado::Interno.buscar_brapi("PETR4", Date.current, token: "segredo", http: invalido) }
    assert_match(/resposta inválida/, erro.message)
  end

  private

  def contar_consultas
    total = 0
    callback = lambda do |_nome, _inicio, _fim, _id, payload|
      total += 1 unless %w[SCHEMA TRANSACTION CACHE].include?(payload[:name])
    end
    ActiveSupport::Notifications.subscribed(callback, "sql.active_record") { yield }
    total
  end

  def resposta_http(classe, corpo)
    codigo = Net::HTTPResponse::CODE_TO_OBJ.key(classe)
    resposta = classe.new("1.1", codigo, "Teste")
    resposta.instance_variable_set(:@read, true)
    resposta.body = corpo
    resposta
  end
end
