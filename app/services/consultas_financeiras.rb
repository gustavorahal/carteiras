module ConsultasFinanceiras
  PosicaoDTO = Data.define(:carteira_id, :data, :itens, :valor_total_base, :completo)
  SaldosCaixaDTO = Data.define(:carteira_id, :data, :itens, :valor_total_base, :completo)
  ResultadosDTO = Data.define(:carteira_id, :inicio, :fim, :itens, :totais_por_moeda, :total_base)
  RentabilidadeDTO = Data.define(:carteira_id, :inicio, :fim, :pontos, :twr_acumulado, :completo, :motivos_incompletude)

  class << self
    def posicao_atual(carteira:, usuario:)
      autorizar!(carteira, usuario)
      data = Date.current
      posicoes = PosicaoAtual.joins(:conta_investimento)
        .where(contas_investimento: { carteira_id: carteira.id }).includes(ativo: :moeda_negociacao)
        .map { |p| { conta_investimento_id: p.conta_investimento_id, ativo_id: p.ativo_id, quantidade: p.quantidade,
          custo_total_local: p.custo_total_local, custo_total_base: p.custo_total_base } }
      montar_posicao(carteira, data, posicoes)
    end

    def posicao_historica(carteira:, data:, usuario:)
      autorizar!(carteira, usuario)
      data = data!(data)
      estado = TransacoesFinanceiras::Interno.projetar(eventos(carteira.investidor), ate: data)
      contas = carteira.contas_investimento.pluck(:id).to_set
      posicoes = estado[:posicoes].values.select { |p| contas.include?(p[:conta_investimento_id]) }
      montar_posicao(carteira, data, posicoes)
    end

    def saldos_caixa(carteira:, data:, usuario:)
      autorizar!(carteira, usuario)
      data = data!(data)
      caixas = carteira.contas_caixa.includes(:moeda, :conta_investimento).to_a
      saldos = LancamentoCaixa.where(conta_caixa_id: caixas.map(&:id)).where(data_efetiva: ..data).group(:conta_caixa_id).sum(:valor)
      cotacoes = Cotacoes.new([], caixas.map(&:moeda_id).uniq, carteira.moeda_base_id, data)
      completo = true
      total = BigDecimal("0")
      itens = caixas.filter_map do |caixa|
        saldo = saldos.fetch(caixa.id, BigDecimal("0"))
        next if saldo.zero?
        cambio = cotacoes.cambio(caixa.moeda_id, carteira.moeda_base_id, data)
        completo = false unless cambio
        valor_base = cambio && (saldo * cambio[:taxa]).round(12)
        total += valor_base if valor_base
        { conta_caixa_id: caixa.id, conta_investimento_id: caixa.conta_investimento_id,
          moeda_id: caixa.moeda_id, moeda: caixa.moeda.codigo, saldo:, taxa_cambio: cambio&.dig(:taxa),
          data_cambio: cambio&.dig(:data), valor_base:, defasagem_cambio: cambio && (data - cambio[:data]).to_i }.then { |item| Financeiro.congelar(item) }
      end.freeze
      SaldosCaixaDTO.new(carteira_id: carteira.id, data:, itens:, valor_total_base: completo ? total : nil, completo:)
    end

    def resultados_realizados(carteira:, inicio:, fim:, usuario:)
      autorizar!(carteira, usuario)
      inicio, fim = periodo!(inicio, fim)
      estado = TransacoesFinanceiras::Interno.projetar(eventos(carteira.investidor), ate: fim)
      contas = carteira.contas_investimento.pluck(:id).to_set
      ativos = Ativo.includes(:moeda_negociacao).where(id: estado[:resultados].map { |r| r[:ativo_id] }).index_by(&:id)
      itens = estado[:resultados].select do |r|
        contas.include?(r[:conta_investimento_id]) && r[:data].between?(inicio, fim)
      end.map do |r|
        ativo = ativos.fetch(r[:ativo_id])
        Financeiro.congelar(r.merge(ativo: ativo.codigo, moeda: ativo.moeda_negociacao.codigo))
      end.freeze
      totais = Financeiro.congelar(itens.group_by { |i| i[:moeda] }.transform_values { |grupo| grupo.sum { |i| i[:resultado_local] } })
      ResultadosDTO.new(carteira_id: carteira.id, inicio:, fim:, itens:, totais_por_moeda: totais,
        total_base: itens.sum { |i| i[:resultado_base] })
    end

    def rentabilidade(carteira:, inicio:, fim:, usuario:)
      autorizar!(carteira, usuario)
      inicio, fim = periodo!(inicio, fim)
      todos_eventos = eventos(carteira.investidor)
      contas = carteira.contas_investimento.pluck(:id).to_set
      caixas = carteira.contas_caixa.includes(:moeda).to_a
      lancamentos = LancamentoCaixa.where(conta_caixa_id: caixas.map(&:id), data_efetiva: ..fim).to_a
      ativo_ids = ativos_dos_eventos(todos_eventos)
      ativos = Ativo.where(id: ativo_ids).index_by(&:id)
      moedas = caixas.map(&:moeda_id) + ativos.values.map(&:moeda_negociacao_id)
      cotacoes = Cotacoes.new(ativo_ids, moedas.uniq, carteira.moeda_base_id, fim)
      fluxos = fluxos_externos(carteira, inicio, fim, cotacoes, todos_eventos, ativos)
      cortes_saldo_inicial = datas_saldo_inicial(carteira, inicio, fim, todos_eventos)
      patrimonios = patrimonios_por_data(carteira, (inicio - 1)..fim, todos_eventos, contas,
        caixas, lancamentos, cotacoes, ativos)
      acumulado = BigDecimal("1")
      cadeia_valida = true
      reiniciar_cadeia = false
      motivos = []
      pontos = (inicio..fim).map do |dia|
        if reiniciar_cadeia
          acumulado = BigDecimal("1")
          cadeia_valida = true
          reiniciar_cadeia = false
        end
        inicial = patrimonios.fetch(dia - 1)
        final = patrimonios.fetch(dia)
        fluxo_info = fluxos.fetch(dia, { valor: BigDecimal("0"), defasagem: nil })
        fluxo = fluxo_info[:valor]
        maior_defasagem = [inicial[:maior_defasagem], final[:maior_defasagem], fluxo_info[:defasagem]].compact.max
        if cortes_saldo_inicial.include?(dia)
          estado = "corte_saldo_inicial"
          twr = nil
          cadeia_valida = false
          reiniciar_cadeia = true
          motivos << "corte_saldo_inicial"
        elsif !inicial[:completo] || !final[:completo] || fluxo.nil?
          estado = "incompleto"
          twr = nil
          cadeia_valida = false
          motivos << "cotacao_ausente"
        elsif inicial[:valor] <= 0
          estado = "sem_patrimonio_inicial_valido"
          twr = nil
          cadeia_valida = false
          motivos << "patrimonio_inicial_nao_positivo"
        else
          estado = "calculado"
          twr = ((final[:valor] - fluxo) / inicial[:valor] - 1).round(12)
          acumulado *= 1 + twr if cadeia_valida
        end
        { data: dia, patrimonio_inicial: inicial[:completo] ? inicial[:valor] : nil,
          patrimonio_final: final[:completo] ? final[:valor] : nil, fluxo_externo_liquido: fluxo,
          twr_diario: twr, twr_acumulado: cadeia_valida ? (acumulado - 1).round(12) : nil,
          estado:, maior_defasagem: }.then { |ponto| Financeiro.congelar(ponto) }
      end.freeze
      completo = pontos.all? { |p| p[:estado] == "calculado" }
      RentabilidadeDTO.new(carteira_id: carteira.id, inicio:, fim:, pontos:,
        twr_acumulado: completo ? (acumulado - 1).round(12) : nil, completo:,
        motivos_incompletude: motivos.uniq.freeze)
    end

    private

    def montar_posicao(carteira, data, posicoes)
      ativos = Ativo.includes(:moeda_negociacao).where(id: posicoes.map { |p| p[:ativo_id] }).index_by(&:id)
      cotacoes = Cotacoes.new(ativos.keys, ativos.values.map(&:moeda_negociacao_id), carteira.moeda_base_id, data)
      completo = true
      total = BigDecimal("0")
      itens = posicoes.map do |p|
        ativo = ativos.fetch(p[:ativo_id])
        preco = cotacoes.preco(ativo.id, data)
        cambio = cotacoes.cambio(ativo.moeda_negociacao_id, carteira.moeda_base_id, data)
        completo = false unless preco && cambio
        local = preco && (p[:quantidade] * preco[:preco]).round(12)
        base = local && cambio && (local * cambio[:taxa]).round(12)
        total += base if base
        { conta_investimento_id: p[:conta_investimento_id], ativo_id: ativo.id, ativo: ativo.codigo,
          quantidade: p[:quantidade], custo_total_local: p[:custo_total_local], custo_total_base: p[:custo_total_base],
          preco: preco&.dig(:preco), data_preco: preco&.dig(:data), valor_mercado_local: local,
          taxa_cambio: cambio&.dig(:taxa), data_cambio: cambio&.dig(:data), valor_mercado_base: base,
          defasagem_preco: preco && (data - preco[:data]).to_i,
          defasagem_cambio: cambio && (data - cambio[:data]).to_i }.then { |item| Financeiro.congelar(item) }
      end.freeze
      PosicaoDTO.new(carteira_id: carteira.id, data:, itens:, valor_total_base: completo ? total : nil, completo:)
    end

    def patrimonios_por_data(carteira, datas, todos_eventos, contas, caixas, lancamentos, cotacoes, ativos)
      ordenados = lancamentos.sort_by { |l| [l.data_efetiva, l.transacao_financeira_id, l.ordem] }
      saldos = Hash.new { |h, k| h[k] = BigDecimal("0") }
      indice_lancamento = 0
      resultado = {}
      TransacoesFinanceiras::Interno.percorrer_estados(todos_eventos, datas) do |data, posicoes, _resultados|
        while indice_lancamento < ordenados.length && ordenados[indice_lancamento].data_efetiva <= data
          lancamento = ordenados[indice_lancamento]
          saldos[lancamento.conta_caixa_id] += lancamento.valor
          indice_lancamento += 1
        end
        resultado[data] = avaliar_patrimonio(carteira, data, posicoes, contas, caixas, saldos, cotacoes, ativos)
      end
      resultado
    end

    def avaliar_patrimonio(carteira, data, posicoes, contas, caixas, saldos, cotacoes, ativos)
      valor = BigDecimal("0")
      completo = true
      defasagens = []
      posicoes.each_value do |p|
        next unless contas.include?(p[:conta_investimento_id])
        ativo = ativos.fetch(p[:ativo_id])
        preco = cotacoes.preco(ativo.id, data)
        cambio = cotacoes.cambio(ativo.moeda_negociacao_id, carteira.moeda_base_id, data)
        if preco && cambio
          valor += p[:quantidade] * preco[:preco] * cambio[:taxa]
          defasagens << (data - preco[:data]).to_i << (data - cambio[:data]).to_i
        else
          completo = false
        end
      end
      caixas.each do |caixa|
        saldo = saldos.fetch(caixa.id, BigDecimal("0"))
        next if saldo.zero?
        cambio = cotacoes.cambio(caixa.moeda_id, carteira.moeda_base_id, data)
        if cambio
          valor += saldo * cambio[:taxa]
          defasagens << (data - cambio[:data]).to_i
        else
          completo = false
        end
      end
      { valor: valor.round(12), completo:, maior_defasagem: defasagens.max }
    end

    def fluxos_externos(carteira, inicio, fim, cotacoes, todos_eventos, ativos)
      revertidas = TransacaoFinanceira.confirmadas.where.not(transacao_revertida_id: nil).pluck(:transacao_revertida_id).to_set
      movimentos = MovimentacaoCaixa.joins(:transacao_financeira)
        .where(transacoes_financeiras: { investidor_id: carteira.investidor_id, estado: "confirmada", data_competencia: inicio..fim })
        .where.not(transacao_financeira_id: revertidas)
        .includes({ conta_caixa_origem: { conta_investimento: :carteira } },
          { conta_caixa_destino: { conta_investimento: :carteira } }, :transacao_financeira)
      fluxos = movimentos.each_with_object({}) do |m, acumulados|
        data = m.data_efetiva
        case m.tipo
        when "aporte"
          next unless m.conta_caixa_destino.carteira.id == carteira.id
          valor = converter_fluxo(m.valor_destino, m.conta_caixa_destino.moeda_id, carteira.moeda_base_id, data, cotacoes)
          acumular_fluxo!(acumulados, data, valor)
        when "resgate"
          next unless m.conta_caixa_origem.carteira.id == carteira.id
          valor = converter_fluxo(m.valor_origem, m.conta_caixa_origem.moeda_id, carteira.moeda_base_id, data, cotacoes)
          acumular_fluxo!(acumulados, data, valor && valor.merge(valor: -valor[:valor]))
        when "transferencia"
          origem_aqui = m.conta_caixa_origem.carteira.id == carteira.id
          destino_aqui = m.conta_caixa_destino.carteira.id == carteira.id
          next if origem_aqui == destino_aqui
          conta = origem_aqui ? m.conta_caixa_origem : m.conta_caixa_destino
          valor = converter_fluxo(origem_aqui ? m.valor_origem : m.valor_destino, conta.moeda_id, carteira.moeda_base_id, data, cotacoes)
          acumular_fluxo!(acumulados, data, valor && valor.merge(valor: origem_aqui ? -valor[:valor] : valor[:valor]))
        end
      end

      contas_da_carteira = carteira.contas_investimento.pluck(:id).to_set
      contas_por_id = ContaInvestimento.where(carteira_id: carteira.investidor.carteiras.select(:id)).pluck(:id, :carteira_id).to_h
      TransacoesFinanceiras::Interno.eventos_efetivos(todos_eventos).each do |evento|
        next unless evento[:data_competencia].between?(inicio, fim)
        d = evento[:detalhe]
        case evento[:tipo]
        when "saldo_inicial"
          next unless contas_da_carteira.include?(d[:conta_investimento_id])
          valor = converter_fluxo_ativo(d[:quantidade], ativos.fetch(d[:ativo_id]), carteira.moeda_base_id,
            evento[:data_competencia], cotacoes)
          acumular_fluxo!(fluxos, evento[:data_competencia], valor)
        when "transferencia_custodia"
          origem_aqui = contas_por_id[d[:conta_origem_id]] == carteira.id
          destino_aqui = contas_por_id[d[:conta_destino_id]] == carteira.id
          next if origem_aqui == destino_aqui
          valor = converter_fluxo_ativo(d[:quantidade], ativos.fetch(d[:ativo_id]), carteira.moeda_base_id,
            evento[:data_competencia], cotacoes)
          valor = valor.merge(valor: -valor[:valor]) if valor && origem_aqui
          acumular_fluxo!(fluxos, evento[:data_competencia], valor)
        end
      end
      fluxos
    end

    def acumular_fluxo!(fluxos, data, valor)
      anterior = fluxos.fetch(data, { valor: BigDecimal("0"), defasagem: nil })
      fluxos[data] = if valor.nil? || anterior[:valor].nil?
        { valor: nil, defasagem: [anterior[:defasagem], valor&.dig(:defasagem)].compact.max }
      else
        { valor: anterior[:valor] + valor[:valor],
          defasagem: [anterior[:defasagem], valor[:defasagem]].compact.max }
      end
    end

    def converter_fluxo(valor, origem_id, destino_id, data, cotacoes)
      cambio = cotacoes.cambio(origem_id, destino_id, data)
      cambio && { valor: (valor * cambio[:taxa]).round(12), defasagem: (data - cambio[:data]).to_i }
    end

    def converter_fluxo_ativo(quantidade, ativo, moeda_base_id, data, cotacoes)
      preco = cotacoes.preco(ativo.id, data)
      cambio = cotacoes.cambio(ativo.moeda_negociacao_id, moeda_base_id, data)
      return unless preco && cambio

      { valor: (quantidade * preco[:preco] * cambio[:taxa]).round(12),
        defasagem: [(data - preco[:data]).to_i, (data - cambio[:data]).to_i].max }
    end

    def ativos_dos_eventos(eventos)
      eventos.flat_map do |evento|
        d = evento[:detalhe] || {}
        Array(d[:negociacoes]).map { |negociacao| negociacao[:ativo_id] } +
          [d[:ativo_id], d[:ativo_origem_id], d[:ativo_destino_id]].compact
      end.uniq
    end

    def datas_saldo_inicial(carteira, inicio, fim, eventos)
      contas = carteira.contas_investimento.pluck(:id).to_set
      TransacoesFinanceiras::Interno.eventos_efetivos(eventos).filter_map do |evento|
        next unless evento[:tipo] == "saldo_inicial" && evento[:data_competencia].between?(inicio, fim)
        evento[:data_competencia] if contas.include?(evento[:detalhe][:conta_investimento_id])
      end.to_set
    end

    def eventos(investidor)
      TransacoesFinanceiras::Interno.eventos_confirmados(investidor)
    end

    def autorizar!(carteira, usuario)
      raise Financeiro::NaoAutorizado unless usuario&.pode_ler?(carteira.espaco)
    end

    def data!(valor)
      return valor if valor.is_a?(Date)
      Date.iso8601(valor.to_s)
    rescue ArgumentError
      raise Financeiro::AtributosInvalidos.new(data: ["inválida"])
    end

    def periodo!(inicio, fim)
      inicio = data!(inicio)
      fim = data!(fim)
      raise Financeiro::AtributosInvalidos.new(periodo: ["início deve ser anterior ou igual ao fim"]) if inicio > fim
      [inicio, fim]
    end
  end

  class Cotacoes
    def initialize(ativo_ids, moeda_ids, moeda_base_id, ate)
      @ativos = CotacaoAtivo.where(ativo_id: ativo_ids, data: ..ate).order(:data).group_by(&:ativo_id)
      ids = (moeda_ids + [moeda_base_id]).uniq
      @cambios = CotacaoCambio.where(moeda_origem_id: ids, moeda_destino_id: ids, data: ..ate).order(:data)
        .group_by { |c| [c.moeda_origem_id, c.moeda_destino_id] }
    end

    def preco(ativo_id, data)
      cotacao = ultima_ate(@ativos[ativo_id], data)
      cotacao && { preco: cotacao.preco, data: cotacao.data }
    end

    def cambio(origem_id, destino_id, data)
      return { taxa: BigDecimal("1"), data: } if origem_id == destino_id
      direta = ultima_ate(@cambios[[origem_id, destino_id]], data)
      return { taxa: direta.taxa, data: direta.data } if direta
      inversa = ultima_ate(@cambios[[destino_id, origem_id]], data)
      inversa && { taxa: (BigDecimal("1") / inversa.taxa).round(12), data: inversa.data }
    end

    private

    def ultima_ate(lista, data)
      ordenada = Array(lista)
      indice_posterior = ordenada.bsearch_index { |cotacao| cotacao.data > data }
      return ordenada.last unless indice_posterior
      indice_posterior.positive? ? ordenada[indice_posterior - 1] : nil
    end
  end
end
