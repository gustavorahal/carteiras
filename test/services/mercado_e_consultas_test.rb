require "test_helper"
require "minitest/mock"

class MercadoEConsultasTest < ActiveSupport::TestCase
  test "cotação manual canônica bloqueia automação até liberação explícita" do
    manual = Mercado.registrar_cotacao_ativo(ativo: @ativo, data: "2026-01-05", preco: "10.50",
      fonte: @fonte_manual, manual: true, usuario: @admin_sistema)
    assert_equal "criada", manual.estado
    ignorada = Mercado.registrar_cotacao_ativo(ativo: @ativo, data: "2026-01-05", preco: "11",
      fonte: @fonte_yahoo, manual: false)
    assert_equal "ignorada_manual", ignorada.estado
    assert_equal BigDecimal("10.5"), manual.cotacao.reload.preco
    Mercado.liberar_automacao(cotacao_ativo: manual.cotacao, usuario: @admin_sistema)
    atualizada = Mercado.registrar_cotacao_ativo(ativo: @ativo, data: "2026-01-05", preco: "11",
      fonte: @fonte_yahoo, manual: false)
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

  test "falha Yahoo preserva valor e não impede os ativos posteriores" do
    outro = Ativo.create!(codigo: "VALE3", mercado: "B3", tipo: "acao", moeda_negociacao: @brl,
      simbolo_yahoo: "VALE3.SA")
    data = Date.new(2026, 1, 5)
    existente = Mercado.registrar_cotacao_ativo(ativo: @ativo, data:, preco: "9", fonte: @fonte_yahoo, manual: false).cotacao
    buscador = lambda do |simbolo, _data|
      raise Net::ReadTimeout, "timeout de teste" if simbolo == @ativo.simbolo_yahoo
      BigDecimal("20")
    end

    assert_raises(RuntimeError) do
      Mercado::Interno.stub(:buscar_yahoo, buscador) { Mercado.buscar_e_registrar_yahoo(data:) }
    end
    assert_equal BigDecimal("9"), existente.reload.preco
    assert_equal BigDecimal("20"), CotacaoAtivo.find_by!(ativo: outro, data:).preco
  end

  test "cliente Yahoo trata timeout e resposta inválida como falhas" do
    timeout = Object.new
    timeout.define_singleton_method(:get_response) { |_uri| raise Net::ReadTimeout, "timeout" }
    assert_raises(Net::ReadTimeout) { Mercado::Interno.buscar_yahoo("PETR4.SA", Date.current, http: timeout) }

    resposta = Net::HTTPOK.new("1.1", "200", "OK")
    resposta.instance_variable_set(:@read, true)
    resposta.body = "não é json"
    invalido = Object.new
    invalido.define_singleton_method(:get_response) { |_uri| resposta }
    erro = assert_raises(RuntimeError) { Mercado::Interno.buscar_yahoo("PETR4.SA", Date.current, http: invalido) }
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
end
