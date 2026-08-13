module TransacoesFinanceiras
  PreviaTransacao = Data.define(:tipo, :data_competencia, :ordem_na_data, :detalhe_normalizado,
    :lancamentos, :liquidacao_liquida, :posicoes_resultantes)
  ResultadoCorrecao = Data.define(:original, :reversao, :substituta)

  class << self
    def prever(tipo:, investidor:, usuario:, atributos:, transacao_original: nil)
      autorizar!(investidor, usuario)
      normalizado = Interno.normalizar(tipo, investidor, atributos)
      if transacao_original
        raise Financeiro::EscopoInvalido.new(transacao_original: ["não pertence ao investidor"]) unless transacao_original.investidor_id == investidor.id
        Interno.validar_elegibilidade_reversao!(transacao_original)
        raise Financeiro::AtributosInvalidos.new(tipo: ["a correção deve conservar o tipo da original"]) unless tipo.to_s == transacao_original.tipo
        raise Financeiro::AtributosInvalidos.new(data_competencia: ["a correção deve conservar a competência da original"]) unless normalizado[:data_competencia] == transacao_original.data_competencia
        if normalizado[:ordem_na_data] && normalizado[:ordem_na_data] != transacao_original.ordem_na_data
          raise Financeiro::AtributosInvalidos.new(ordem_na_data: ["a correção deve conservar a ordem da original"])
        end
      end
      ordem = transacao_original&.ordem_na_data || normalizado[:ordem_na_data] || Interno.proxima_ordem(investidor, normalizado[:data_competencia])
      candidato = Interno.evento_em_memoria(tipo:, investidor:, normalizado:, ordem:)
      eventos = Interno.eventos_confirmados(investidor)
      eventos << Interno.reversao_em_memoria(transacao_original) if transacao_original
      estado = Interno.projetar(eventos + [candidato])
      Interno.previa(tipo, normalizado, ordem, estado)
    end

    def criar_rascunho(tipo:, investidor:, usuario:, atributos:, chave_idempotencia: nil, origem: "manual", importacao: nil)
      autorizar!(investidor, usuario)
      tipo = tipo.to_s
      raise Financeiro::AtributosInvalidos.new(tipo: ["inválido"]) unless (TransacaoFinanceira::TIPOS - ["reversao"]).include?(tipo)
      raise Financeiro::AtributosInvalidos.new(origem: ["inválida"]) unless %w[manual importacao].include?(origem.to_s)
      if origem.to_s == "importacao"
        unless importacao&.investidor_id == investidor.id
          raise Financeiro::EscopoInvalido.new(importacao_financeira: ["não pertence ao investidor"])
        end
      elsif importacao
        raise Financeiro::AtributosInvalidos.new(importacao_financeira: ["só se aplica à origem importação"])
      end

      chave = Interno.texto_opcional(chave_idempotencia, :chave_idempotencia)
      if chave && (existente = investidor.transacoes_financeiras.find_by(chave_idempotencia: chave))
        raise Financeiro::ConflitoIdempotencia.new(tipo: ["não corresponde à chave já utilizada"]) if existente.tipo != tipo
        return existente
      end

      normalizado = Interno.normalizar(tipo, investidor, atributos)
      begin
        TransacaoFinanceira.transaction do
          transacao = investidor.transacoes_financeiras.create!(
            tipo:, origem: origem.to_s, estado: "rascunho", criado_por: usuario, importacao_financeira: importacao,
            data_competencia: normalizado[:data_competencia], ordem_na_data: normalizado[:ordem_na_data],
            observacao: normalizado[:observacao], chave_idempotencia: chave
          )
          Interno.persistir_detalhe!(transacao, normalizado)
          transacao
        end
      rescue ActiveRecord::RecordNotUnique
        existente = investidor.transacoes_financeiras.find_by!(chave_idempotencia: chave)
        raise Financeiro::ConflitoIdempotencia.new(tipo: ["não corresponde à chave já utilizada"]) if existente.tipo != tipo
        existente
      end
    end

    def atualizar_rascunho(transacao:, usuario:, atributos:)
      autorizar!(transacao.investidor, usuario)
      raise Financeiro::EstadoInvalido.new(estado: ["apenas rascunhos podem ser atualizados"]) unless transacao.rascunho? && !transacao.reversao?

      Interno.com_bloqueios(transacao.investidor) do
        transacao.lock!
        raise Financeiro::EstadoInvalido.new(estado: ["mudou durante a atualização"]) unless transacao.rascunho?

        normalizado = Interno.normalizar(transacao.tipo, transacao.investidor, atributos)
        Interno.apagar_detalhe!(transacao)
        transacao.update!(data_competencia: normalizado[:data_competencia], ordem_na_data: normalizado[:ordem_na_data], observacao: normalizado[:observacao])
        Interno.persistir_detalhe!(transacao, normalizado)
        transacao
      end
    end

    def excluir_rascunho(transacao:, usuario:)
      autorizar!(transacao.investidor, usuario)
      raise Financeiro::EstadoInvalido.new(estado: ["apenas rascunhos podem ser excluídos"]) unless transacao.rascunho? && !transacao.reversao?

      Interno.com_bloqueios(transacao.investidor) do
        transacao.lock!
        raise Financeiro::EstadoInvalido.new(estado: ["mudou durante a exclusão"]) unless transacao.rascunho?

        Interno.apagar_detalhe!(transacao)
        transacao.destroy!
      end
      true
    end

    def confirmar(transacao:, usuario:)
      autorizar!(transacao.investidor, usuario)
      Interno.com_bloqueios(transacao.investidor) do
        transacao.lock!
        raise Financeiro::EstadoInvalido.new(estado: ["apenas rascunhos podem ser confirmados"]) unless transacao.rascunho? && !transacao.reversao?

        Interno.validar_cardinalidade_detalhe!(transacao)
        normalizado = Interno.normalizado_do_banco(transacao)
        if normalizado[:data_competencia] > Date.current
          raise Financeiro::AtributosInvalidos.new(data_competencia: ["só pode ser confirmada quando a competência chegar"])
        end
        Interno.validar_disponibilidade!(transacao.investidor, normalizado)
        ordem = transacao.ordem_na_data || Interno.proxima_ordem(transacao.investidor, transacao.data_competencia)
        candidato = Interno.evento_em_memoria(tipo: transacao.tipo, investidor: transacao.investidor, normalizado:, ordem:, id: transacao.id)
        Interno.projetar(Interno.eventos_confirmados(transacao.investidor) + [candidato])

        transacao.update_columns(estado: "confirmada", ordem_na_data: ordem, confirmado_por_id: usuario.id,
          confirmada_em: Time.current, updated_at: Time.current)
        Interno.com_escrita_derivada { Interno.substituir_lancamentos!(transacao, Interno.lancamentos(normalizado)) }
        Interno.reconstruir_posicoes!(transacao.investidor)
        transacao.reload
      end
    end

    def reverter(transacao:, usuario:)
      autorizar!(transacao.investidor, usuario)
      Interno.com_bloqueios(transacao.investidor) do
        transacao.lock!
        Interno.validar_elegibilidade_reversao!(transacao)
        reversao_memoria = Interno.reversao_em_memoria(transacao)
        Interno.projetar(Interno.eventos_confirmados(transacao.investidor) + [reversao_memoria])

        reversao = TransacaoFinanceira.create!(investidor: transacao.investidor, tipo: "reversao", origem: "sistema",
          data_competencia: transacao.data_competencia, ordem_na_data: transacao.ordem_na_data, estado: "confirmada",
          criado_por: usuario, confirmado_por: usuario, confirmada_em: Time.current, transacao_revertida: transacao)
        Interno.com_escrita_derivada do
          transacao.lancamentos_caixa.order(:ordem).each do |original|
            reversao.lancamentos_caixa.create!(ordem: original.ordem, conta_caixa: original.conta_caixa,
              data_efetiva: original.data_efetiva, natureza: original.natureza, valor: -original.valor,
              lancamento_original: original)
          end
        end
        Interno.reconstruir_posicoes!(transacao.investidor)
        reversao
      end
    end

    def corrigir(transacao:, usuario:, atributos:)
      autorizar!(transacao.investidor, usuario)
      Interno.com_bloqueios(transacao.investidor) do
        transacao.lock!
        Interno.validar_elegibilidade_reversao!(transacao)
        normalizado = Interno.normalizar(transacao.tipo, transacao.investidor, atributos)
        unless normalizado[:data_competencia] == transacao.data_competencia
          raise Financeiro::AtributosInvalidos.new(data_competencia: ["a correção deve conservar a competência da original"])
        end
        if normalizado[:ordem_na_data] && normalizado[:ordem_na_data] != transacao.ordem_na_data
          raise Financeiro::AtributosInvalidos.new(ordem_na_data: ["a correção deve conservar a ordem da original"])
        end
        Interno.validar_disponibilidade!(transacao.investidor, normalizado)
        eventos = Interno.eventos_confirmados(transacao.investidor)
        eventos << Interno.reversao_em_memoria(transacao)
        eventos << Interno.evento_em_memoria(tipo: transacao.tipo, investidor: transacao.investidor,
          normalizado:, ordem: transacao.ordem_na_data)
        Interno.projetar(eventos)

        reversao = TransacaoFinanceira.create!(investidor: transacao.investidor, tipo: "reversao", origem: "sistema",
          data_competencia: transacao.data_competencia, ordem_na_data: transacao.ordem_na_data, estado: "confirmada",
          criado_por: usuario, confirmado_por: usuario, confirmada_em: Time.current, transacao_revertida: transacao)
        Interno.com_escrita_derivada do
          transacao.lancamentos_caixa.order(:ordem).each do |original|
            reversao.lancamentos_caixa.create!(ordem: original.ordem, conta_caixa: original.conta_caixa,
              data_efetiva: original.data_efetiva, natureza: original.natureza, valor: -original.valor,
              lancamento_original: original)
          end
        end
        substituta = TransacaoFinanceira.create!(investidor: transacao.investidor, tipo: transacao.tipo,
          origem: transacao.origem, data_competencia: transacao.data_competencia, ordem_na_data: transacao.ordem_na_data,
          estado: "rascunho", criado_por: usuario, observacao: normalizado[:observacao],
          importacao_financeira: transacao.importacao_financeira)
        Interno.persistir_detalhe!(substituta, normalizado)
        substituta.update_columns(estado: "confirmada", confirmado_por_id: usuario.id, confirmada_em: Time.current, updated_at: Time.current)
        Interno.com_escrita_derivada { Interno.substituir_lancamentos!(substituta, Interno.lancamentos(normalizado)) }
        Interno.reconstruir_posicoes!(transacao.investidor)
        ResultadoCorrecao.new(original: transacao.reload, reversao:, substituta: substituta.reload)
      end
    end

    private

    def autorizar!(investidor, usuario)
      raise Financeiro::NaoAutorizado unless usuario&.pode_editar?(investidor.espaco)
      raise Financeiro::RegistroArquivado.new(espaco: ["está arquivado"]) if investidor.espaco.arquivado?
      raise Financeiro::RegistroArquivado.new(investidor: ["está arquivado"]) if investidor.arquivado?
    end
  end

  module Interno
    module_function

    Q12 = BigDecimal("0.000000000001")
    Q10 = BigDecimal("0.0000000001")

    def normalizar(tipo, investidor, atributos)
      exigir_hash_simbolico!(atributos)
      tipo = tipo.to_s
      case tipo
      when "nota_negociacao" then normalizar_nota(investidor, atributos)
      when "provento" then normalizar_provento(investidor, atributos)
      when "movimentacao_caixa" then normalizar_movimentacao(investidor, atributos)
      when "saldo_inicial" then normalizar_saldo_inicial(investidor, atributos)
      when "saldo_inicial_caixa" then normalizar_saldo_inicial_caixa(investidor, atributos)
      when "transferencia_custodia" then normalizar_transferencia_custodia(investidor, atributos)
      when "evento_corporativo" then normalizar_evento_corporativo(investidor, atributos)
      else raise Financeiro::AtributosInvalidos.new(tipo: ["inválido"])
      end.then { |valor| Financeiro.congelar(valor) }
    end

    def normalizar_nota(investidor, a)
      validar_chaves!(a, %i[conta_caixa_id data_negociacao data_liquidacao custo_operacional_total taxa_conversao_base negociacoes observacao ordem_na_data])
      caixa = caixa!(a[:conta_caixa_id], investidor)
      negociacoes = a[:negociacoes]
      raise Financeiro::AtributosInvalidos.new(negociacoes: ["deve conter ao menos uma linha"]) unless negociacoes.is_a?(Array) && negociacoes.any?
      data_negociacao = data!(a[:data_negociacao], :data_negociacao)
      data_liquidacao = data!(a[:data_liquidacao], :data_liquidacao)
      raise Financeiro::AtributosInvalidos.new(data_negociacao: ["deve ser anterior ou igual à liquidação"]) if data_negociacao > data_liquidacao
      custo = decimal!(a[:custo_operacional_total], :custo_operacional_total, escala: 12, minimo: 0)
      taxa = decimal!(a[:taxa_conversao_base], :taxa_conversao_base, escala: 12, minimo_exclusivo: 0)
      validar_taxa_base!(caixa, taxa)
      linhas = negociacoes.each_with_index.map do |linha, indice|
        exigir_hash_simbolico!(linha)
        validar_chaves!(linha, %i[ativo_id natureza quantidade preco_unitario custo_alocado], opcionais: %i[custo_alocado])
        ativo = ativo!(linha[:ativo_id])
        raise Financeiro::RegistroArquivado.new(ativo_id: ["está arquivado"]) if ativo.arquivado?
        raise Financeiro::EscopoInvalido.new(ativo_id: ["usa moeda diferente da conta de caixa"]) unless ativo.moeda_negociacao_id == caixa.moeda_id
        natureza = linha[:natureza].to_s
        raise Financeiro::AtributosInvalidos.new(natureza: ["inválida"]) unless %w[compra venda].include?(natureza)
        { ordem: indice + 1, ativo_id: ativo.id, natureza:,
          quantidade: decimal!(linha[:quantidade], :quantidade, escala: 10, minimo_exclusivo: 0),
          preco_unitario: decimal!(linha[:preco_unitario], :preco_unitario, escala: 12, minimo_exclusivo: 0),
          custo_alocado_informado: linha.key?(:custo_alocado) ? decimal!(linha[:custo_alocado], :custo_alocado, escala: 12, minimo: 0) : nil }
      end
      brutos = linhas.map { |linha| (linha[:quantidade] * linha[:preco_unitario]).round(12) }
      total_bruto = brutos.sum
      raise Financeiro::AtributosInvalidos.new(negociacoes: ["o valor bruto total deve ser positivo após quantização"]) unless total_bruto.positive?
      informados = linhas.map { |linha| linha.delete(:custo_alocado_informado) }
      if informados.any?
        unless informados.all?
          raise Financeiro::AtributosInvalidos.new(custo_alocado: ["deve ser informado em todas as negociações ou em nenhuma"])
        end
        unless informados.sum == custo
          raise Financeiro::AtributosInvalidos.new(custo_alocado: ["a soma deve ser exatamente igual ao custo operacional total"])
        end
        rateados = informados
      else
        rateados = brutos.each_with_index.map do |bruto, indice|
          indice == brutos.length - 1 ? custo : (custo * bruto / total_bruto).round(12)
        end
        rateados[-1] = custo - rateados[0...-1].sum
      end
      linhas.each_with_index { |linha, indice| linha[:custo_alocado] = rateados[indice] }
      comum(a).merge(conta_caixa_id: caixa.id, conta_investimento_id: caixa.conta_investimento_id, data_negociacao:, data_liquidacao:,
        data_competencia: data_liquidacao, custo_operacional_total: custo, taxa_conversao_base: taxa,
        negociacoes: linhas)
    end

    def normalizar_provento(investidor, a)
      validar_chaves!(a, %i[conta_caixa_id ativo_id tipo_provento data_base data_pagamento quantidade_referencia valor_bruto retencoes taxa_conversao_base observacao ordem_na_data])
      caixa = caixa!(a[:conta_caixa_id], investidor)
      ativo = ativo!(a[:ativo_id])
      raise Financeiro::RegistroArquivado.new(ativo_id: ["está arquivado"]) if ativo.arquivado?
      raise Financeiro::EscopoInvalido.new(ativo_id: ["usa moeda diferente da conta de caixa"]) unless ativo.moeda_negociacao_id == caixa.moeda_id
      tipo = a[:tipo_provento].to_s
      raise Financeiro::AtributosInvalidos.new(tipo_provento: ["inválido"]) unless %w[dividendo jcp rendimento juros outro].include?(tipo)
      bruto = decimal!(a[:valor_bruto], :valor_bruto, escala: 12, minimo: 0)
      retencoes = decimal!(a[:retencoes], :retencoes, escala: 12, minimo: 0)
      raise Financeiro::AtributosInvalidos.new(retencoes: ["não pode exceder o bruto"]) if retencoes > bruto
      taxa = decimal!(a[:taxa_conversao_base], :taxa_conversao_base, escala: 12, minimo_exclusivo: 0)
      validar_taxa_base!(caixa, taxa)
      data_pagamento = data!(a[:data_pagamento], :data_pagamento)
      comum(a).merge(conta_caixa_id: caixa.id, conta_investimento_id: caixa.conta_investimento_id, ativo_id: ativo.id, tipo_provento: tipo,
        data_base: data!(a[:data_base], :data_base), data_pagamento:, data_competencia: data_pagamento,
        quantidade_referencia: decimal!(a[:quantidade_referencia], :quantidade_referencia, escala: 10, minimo: 0),
        valor_bruto: bruto, retencoes:, valor_liquido: bruto - retencoes, taxa_conversao_base: taxa)
    end

    def normalizar_movimentacao(investidor, a)
      tipo = a[:tipo_movimentacao].to_s
      permitidas = case tipo
      when "aporte" then %i[tipo_movimentacao conta_caixa_destino_id valor data_efetiva observacao ordem_na_data]
      when "resgate" then %i[tipo_movimentacao conta_caixa_origem_id valor data_efetiva observacao ordem_na_data]
      when "transferencia" then %i[tipo_movimentacao conta_caixa_origem_id conta_caixa_destino_id valor data_efetiva observacao ordem_na_data]
      when "cambio" then %i[tipo_movimentacao conta_caixa_origem_id conta_caixa_destino_id valor_origem valor_destino data_efetiva observacao ordem_na_data]
      else raise Financeiro::AtributosInvalidos.new(tipo_movimentacao: ["inválido"])
      end
      validar_chaves!(a, permitidas)
      origem = caixa!(a[:conta_caixa_origem_id], investidor) if a.key?(:conta_caixa_origem_id)
      destino = caixa!(a[:conta_caixa_destino_id], investidor) if a.key?(:conta_caixa_destino_id)
      raise Financeiro::AtributosInvalidos.new(contas: ["devem ser distintas"]) if origem && destino && origem.id == destino.id
      if tipo == "transferencia"
        raise Financeiro::EscopoInvalido.new(contas: ["devem usar a mesma moeda"]) unless origem.moeda_id == destino.moeda_id
        valor_origem = valor_destino = decimal!(a[:valor], :valor, escala: 12, minimo_exclusivo: 0)
      elsif tipo == "cambio"
        raise Financeiro::EscopoInvalido.new(contas: ["devem usar moedas distintas"]) if origem.moeda_id == destino.moeda_id
        raise Financeiro::EscopoInvalido.new(contas: ["devem pertencer à mesma carteira"]) unless origem.carteira.id == destino.carteira.id
        valor_origem = decimal!(a[:valor_origem], :valor_origem, escala: 12, minimo_exclusivo: 0)
        valor_destino = decimal!(a[:valor_destino], :valor_destino, escala: 12, minimo_exclusivo: 0)
      elsif tipo == "aporte"
        valor_destino = decimal!(a[:valor], :valor, escala: 12, minimo_exclusivo: 0)
      else
        valor_origem = decimal!(a[:valor], :valor, escala: 12, minimo_exclusivo: 0)
      end
      data_efetiva = data!(a[:data_efetiva], :data_efetiva)
      comum(a).merge(tipo_movimentacao: tipo, conta_caixa_origem_id: origem&.id,
        conta_caixa_destino_id: destino&.id, valor_origem:, valor_destino:,
        data_efetiva:, data_competencia: data_efetiva)
    end

    def normalizar_saldo_inicial(investidor, a)
      validar_chaves!(a, %i[conta_investimento_id ativo_id quantidade custo_total_local custo_total_base
        preco_medio_local preco_medio_base custo_desconhecido fonte_custo data_efetiva observacao ordem_na_data],
        opcionais: %i[custo_total_local custo_total_base preco_medio_local preco_medio_base custo_desconhecido fonte_custo observacao ordem_na_data])
      conta = conta_investimento!(a[:conta_investimento_id], investidor)
      ativo = ativo_disponivel!(a[:ativo_id])
      data_efetiva = data!(a[:data_efetiva], :data_efetiva)
      quantidade = decimal!(a[:quantidade], :quantidade, escala: 10, minimo_exclusivo: 0)
      usa_totais = a[:custo_total_local].present? || a[:custo_total_base].present?
      usa_precos_medios = a[:preco_medio_local].present? || a[:preco_medio_base].present?
      custo_desconhecido = a[:custo_desconhecido].to_s == "1"
      if custo_desconhecido && (usa_totais || usa_precos_medios)
        raise Financeiro::AtributosInvalidos.new(custo: ["não deve ser informado quando marcado como desconhecido"])
      elsif !custo_desconhecido && !(usa_totais ^ usa_precos_medios)
        raise Financeiro::AtributosInvalidos.new(custo: ["informe os custos totais ou os preços médios, sem misturar os dois modos"])
      end

      if custo_desconhecido
        custo_total_local = custo_total_base = preco_medio_local = preco_medio_base = nil
      elsif usa_totais
        custo_total_local = decimal!(a[:custo_total_local], :custo_total_local, escala: 12, minimo: 0)
        custo_total_base = decimal!(a[:custo_total_base], :custo_total_base, escala: 12, minimo: 0)
        preco_medio_local = preco_medio_base = nil
      else
        preco_medio_local = decimal!(a[:preco_medio_local], :preco_medio_local, escala: 12, minimo_exclusivo: 0)
        preco_medio_base = if a[:preco_medio_base].present?
          decimal!(a[:preco_medio_base], :preco_medio_base, escala: 12, minimo_exclusivo: 0)
        elsif ativo.moeda_negociacao_id == conta.carteira.moeda_base_id
          preco_medio_local
        else
          raise Financeiro::AtributosInvalidos.new(preco_medio_base: ["é obrigatório quando a moeda do ativo difere da moeda-base"])
        end
        custo_total_local = (quantidade * preco_medio_local).round(12)
        custo_total_base = (quantidade * preco_medio_base).round(12)
      end
      fonte_custo = custo_desconhecido ? "desconhecido" : (a[:fonte_custo].presence || "manual")
      unless SaldoInicial::FONTES_CUSTO.include?(fonte_custo)
        raise Financeiro::AtributosInvalidos.new(fonte_custo: ["inválida"])
      end

      comum(a).merge(conta_investimento_id: conta.id, ativo_id: ativo.id,
        quantidade:, custo_total_local:, custo_total_base:,
        preco_medio_local_informado: preco_medio_local,
        preco_medio_base_informado: preco_medio_base, fonte_custo:, custo_desconhecido:,
        data_efetiva:, data_competencia: data_efetiva)
    end

    def normalizar_saldo_inicial_caixa(investidor, a)
      validar_chaves!(a, %i[conta_caixa_id valor data_efetiva observacao ordem_na_data],
        opcionais: %i[observacao ordem_na_data])
      caixa = caixa!(a[:conta_caixa_id], investidor)
      valor = decimal!(a[:valor], :valor, escala: 12)
      raise Financeiro::AtributosInvalidos.new(valor: ["deve ser diferente de zero"]) if valor.zero?
      data_efetiva = data!(a[:data_efetiva], :data_efetiva)
      comum(a).merge(conta_caixa_id: caixa.id, conta_investimento_id: caixa.conta_investimento_id,
        valor_saldo_inicial: valor, data_efetiva:, data_competencia: data_efetiva)
    end

    def normalizar_transferencia_custodia(investidor, a)
      validar_chaves!(a, %i[conta_origem_id conta_destino_id ativo_id quantidade data_efetiva observacao ordem_na_data])
      origem = conta_investimento!(a[:conta_origem_id], investidor)
      destino = conta_investimento!(a[:conta_destino_id], investidor)
      raise Financeiro::AtributosInvalidos.new(contas: ["devem ser distintas"]) if origem.id == destino.id
      unless origem.carteira.moeda_base_id == destino.carteira.moeda_base_id
        raise Financeiro::EscopoInvalido.new(contas: ["devem pertencer a carteiras com a mesma moeda-base"])
      end
      ativo = ativo_disponivel!(a[:ativo_id])
      data_efetiva = data!(a[:data_efetiva], :data_efetiva)
      comum(a).merge(conta_origem_id: origem.id, conta_destino_id: destino.id, ativo_id: ativo.id,
        quantidade: decimal!(a[:quantidade], :quantidade, escala: 10, minimo_exclusivo: 0),
        data_efetiva:, data_competencia: data_efetiva)
    end

    def normalizar_evento_corporativo(investidor, a)
      validar_chaves!(a, %i[tipo_evento conta_investimento_id ativo_origem_id ativo_destino_id quantidade_final data_efetiva observacao ordem_na_data],
        opcionais: %i[ativo_destino_id observacao ordem_na_data])
      tipo = a[:tipo_evento].to_s
      unless EventoCorporativo::TIPOS.include?(tipo)
        raise Financeiro::AtributosInvalidos.new(tipo_evento: ["inválido"])
      end
      conta = conta_investimento!(a[:conta_investimento_id], investidor)
      origem = ativo_disponivel!(a[:ativo_origem_id])
      destino = ativo_disponivel!(a[:ativo_destino_id]) if a[:ativo_destino_id]
      if tipo.in?(%w[conversao incorporacao])
        if destino.nil? || destino.id == origem.id
          raise Financeiro::AtributosInvalidos.new(ativo_destino_id: ["é obrigatório e deve diferir da origem"])
        end
        unless destino.moeda_negociacao_id == origem.moeda_negociacao_id
          raise Financeiro::EscopoInvalido.new(ativo_destino_id: ["deve usar a mesma moeda de negociação da origem"])
        end
      elsif destino
        raise Financeiro::AtributosInvalidos.new(ativo_destino_id: ["não se aplica a este tipo de evento"])
      end
      data_efetiva = data!(a[:data_efetiva], :data_efetiva)
      comum(a).merge(tipo_evento: tipo, conta_investimento_id: conta.id, ativo_origem_id: origem.id,
        ativo_destino_id: destino&.id,
        quantidade_final: decimal!(a[:quantidade_final], :quantidade_final, escala: 10, minimo_exclusivo: 0),
        data_efetiva:, data_competencia: data_efetiva)
    end

    def comum(a)
      { observacao: texto_opcional(a[:observacao], :observacao), ordem_na_data: ordem!(a[:ordem_na_data]) }
    end

    def validar_disponibilidade!(investidor, detalhe)
      ids = [detalhe[:conta_caixa_id], detalhe[:conta_caixa_origem_id], detalhe[:conta_caixa_destino_id]].compact
      caixas = ContaCaixa.includes({ conta_investimento: { carteira: :investidor } }, :moeda).where(id: ids)
      caixas.each do |caixa|
        unless caixa.investidor.id == investidor.id
          raise Financeiro::EscopoInvalido.new(conta_caixa_id: ["não pertence ao investidor"])
        end
        if caixa.arquivado? || caixa.conta_investimento.arquivado? || caixa.carteira.arquivado? || caixa.moeda.arquivado?
          raise Financeiro::RegistroArquivado.new(conta_caixa_id: ["está indisponível"])
        end
      end
      Array(detalhe[:negociacoes]).each { |n| raise Financeiro::RegistroArquivado.new(ativo_id: ["está arquivado"]) if Ativo.find(n[:ativo_id]).arquivado? }
      [detalhe[:ativo_id], detalhe[:ativo_origem_id], detalhe[:ativo_destino_id]].compact.each do |ativo_id|
        raise Financeiro::RegistroArquivado.new(ativo_id: ["está arquivado"]) if Ativo.find(ativo_id).arquivado?
      end
      [detalhe[:conta_investimento_id], detalhe[:conta_origem_id], detalhe[:conta_destino_id]].compact.each do |conta_id|
        conta_investimento!(conta_id, investidor)
      end
    end

    def persistir_detalhe!(transacao, d)
      case transacao.tipo
      when "nota_negociacao"
        nota = transacao.create_nota_negociacao!(conta_caixa_id: d[:conta_caixa_id], data_negociacao: d[:data_negociacao],
          data_liquidacao: d[:data_liquidacao], custo_operacional_total: d[:custo_operacional_total], taxa_conversao_base: d[:taxa_conversao_base])
        d[:negociacoes].each { |n| nota.negociacoes.create!(n) }
      when "provento"
        transacao.create_provento!(conta_caixa_id: d[:conta_caixa_id], ativo_id: d[:ativo_id], tipo: d[:tipo_provento],
          data_base: d[:data_base], data_pagamento: d[:data_pagamento], quantidade_referencia: d[:quantidade_referencia],
          valor_bruto: d[:valor_bruto], retencoes: d[:retencoes], valor_liquido: d[:valor_liquido], taxa_conversao_base: d[:taxa_conversao_base])
      when "movimentacao_caixa"
        transacao.create_movimentacao_caixa!(tipo: d[:tipo_movimentacao], conta_caixa_origem_id: d[:conta_caixa_origem_id],
          conta_caixa_destino_id: d[:conta_caixa_destino_id], valor_origem: d[:valor_origem], valor_destino: d[:valor_destino], data_efetiva: d[:data_efetiva])
      when "saldo_inicial"
        transacao.create_saldo_inicial!(conta_investimento_id: d[:conta_investimento_id], ativo_id: d[:ativo_id],
          quantidade: d[:quantidade], custo_total_local: d[:custo_total_local], custo_total_base: d[:custo_total_base],
          preco_medio_local_informado: d[:preco_medio_local_informado],
          preco_medio_base_informado: d[:preco_medio_base_informado], fonte_custo: d[:fonte_custo])
      when "saldo_inicial_caixa"
        transacao.create_saldo_inicial_caixa!(conta_caixa_id: d[:conta_caixa_id], valor: d[:valor_saldo_inicial])
      when "transferencia_custodia"
        transacao.create_transferencia_custodia!(conta_origem_id: d[:conta_origem_id], conta_destino_id: d[:conta_destino_id],
          ativo_id: d[:ativo_id], quantidade: d[:quantidade])
      when "evento_corporativo"
        transacao.create_evento_corporativo!(tipo: d[:tipo_evento], conta_investimento_id: d[:conta_investimento_id],
          ativo_origem_id: d[:ativo_origem_id], ativo_destino_id: d[:ativo_destino_id], quantidade_final: d[:quantidade_final])
      end
    end

    def apagar_detalhe!(transacao)
      if (nota = transacao.nota_negociacao)
        Negociacao.where(nota_negociacao_id: nota.id).delete_all
        nota.delete
      end
      transacao.provento&.delete
      transacao.movimentacao_caixa&.delete
      transacao.saldo_inicial&.delete
      transacao.saldo_inicial_caixa&.delete
      transacao.transferencia_custodia&.delete
      transacao.evento_corporativo&.delete
      transacao.association(:nota_negociacao).reset
      transacao.association(:provento).reset
      transacao.association(:movimentacao_caixa).reset
      transacao.association(:saldo_inicial).reset
      transacao.association(:saldo_inicial_caixa).reset
      transacao.association(:transferencia_custodia).reset
      transacao.association(:evento_corporativo).reset
    end

    def normalizado_do_banco(t)
      comum = { observacao: t.observacao, ordem_na_data: t.ordem_na_data, data_competencia: t.data_competencia }
      case t.tipo
      when "nota_negociacao"
        n = t.nota_negociacao or raise Financeiro::AtributosInvalidos.new(detalhe: ["ausente"])
        comum.merge(conta_caixa_id: n.conta_caixa_id, conta_investimento_id: n.conta_caixa.conta_investimento_id,
          data_negociacao: n.data_negociacao, data_liquidacao: n.data_liquidacao,
          custo_operacional_total: n.custo_operacional_total, taxa_conversao_base: n.taxa_conversao_base,
          negociacoes: n.negociacoes.sort_by(&:ordem).map { |op| { ordem: op.ordem, ativo_id: op.ativo_id, natureza: op.natureza,
            quantidade: op.quantidade, preco_unitario: op.preco_unitario, custo_alocado: op.custo_alocado } })
      when "provento"
        p = t.provento or raise Financeiro::AtributosInvalidos.new(detalhe: ["ausente"])
        comum.merge(conta_caixa_id: p.conta_caixa_id, conta_investimento_id: p.conta_caixa.conta_investimento_id,
          ativo_id: p.ativo_id, tipo_provento: p.tipo,
          data_base: p.data_base, data_pagamento: p.data_pagamento, quantidade_referencia: p.quantidade_referencia,
          valor_bruto: p.valor_bruto, retencoes: p.retencoes, valor_liquido: p.valor_liquido, taxa_conversao_base: p.taxa_conversao_base)
      when "movimentacao_caixa"
        m = t.movimentacao_caixa or raise Financeiro::AtributosInvalidos.new(detalhe: ["ausente"])
        comum.merge(tipo_movimentacao: m.tipo, conta_caixa_origem_id: m.conta_caixa_origem_id,
          conta_caixa_destino_id: m.conta_caixa_destino_id, valor_origem: m.valor_origem,
          valor_destino: m.valor_destino, data_efetiva: m.data_efetiva)
      when "saldo_inicial"
        s = t.saldo_inicial or raise Financeiro::AtributosInvalidos.new(detalhe: ["ausente"])
        comum.merge(conta_investimento_id: s.conta_investimento_id, ativo_id: s.ativo_id,
          quantidade: s.quantidade, custo_total_local: s.custo_total_local,
          custo_total_base: s.custo_total_base,
          preco_medio_local_informado: s.preco_medio_local_informado,
          preco_medio_base_informado: s.preco_medio_base_informado,
          fonte_custo: s.fonte_custo, data_efetiva: t.data_competencia)
      when "saldo_inicial_caixa"
        s = t.saldo_inicial_caixa or raise Financeiro::AtributosInvalidos.new(detalhe: ["ausente"])
        comum.merge(conta_caixa_id: s.conta_caixa_id, conta_investimento_id: s.conta_caixa.conta_investimento_id,
          valor_saldo_inicial: s.valor, data_efetiva: t.data_competencia)
      when "transferencia_custodia"
        c = t.transferencia_custodia or raise Financeiro::AtributosInvalidos.new(detalhe: ["ausente"])
        comum.merge(conta_origem_id: c.conta_origem_id, conta_destino_id: c.conta_destino_id,
          ativo_id: c.ativo_id, quantidade: c.quantidade, data_efetiva: t.data_competencia)
      when "evento_corporativo"
        e = t.evento_corporativo or raise Financeiro::AtributosInvalidos.new(detalhe: ["ausente"])
        comum.merge(tipo_evento: e.tipo, conta_investimento_id: e.conta_investimento_id,
          ativo_origem_id: e.ativo_origem_id, ativo_destino_id: e.ativo_destino_id,
          quantidade_final: e.quantidade_final, data_efetiva: t.data_competencia)
      end.then { |valor| Financeiro.congelar(valor) }
    end

    def eventos_confirmados(investidor)
      reversoes = investidor.transacoes_financeiras.confirmadas.where(tipo: "reversao").pluck(:transacao_revertida_id).to_set
      investidor.transacoes_financeiras.confirmadas.where.not(tipo: "reversao")
        .includes({ nota_negociacao: [:negociacoes, :conta_caixa] }, { provento: :conta_caixa }, :movimentacao_caixa,
          :saldo_inicial, { saldo_inicial_caixa: :conta_caixa }, :transferencia_custodia, :evento_corporativo).map do |t|
        evento_em_memoria(tipo: t.tipo, investidor:, normalizado: normalizado_do_banco(t), ordem: t.ordem_na_data, id: t.id, tombstone: reversoes.include?(t.id))
      end
    end

    def evento_em_memoria(tipo:, investidor:, normalizado:, ordem:, id: nil, tombstone: false)
      { id:, tipo:, investidor_id: investidor.id, data_competencia: normalizado[:data_competencia], ordem:, detalhe: normalizado, tombstone: }
    end

    def reversao_em_memoria(original)
      { id: nil, tipo: "reversao", investidor_id: original.investidor_id, data_competencia: original.data_competencia,
        ordem: original.ordem_na_data, alvo_id: original.id, tombstone: false }
    end

    def projetar(eventos, ate: nil)
      posicoes = {}
      resultados = []
      chaves_utilizadas = Set.new
      caixas_utilizadas = Set.new
      eventos_efetivos(eventos).each do |evento|
        break if ate && evento[:data_competencia] > ate
        aplicar_evento!(evento, posicoes, resultados, chaves_utilizadas, caixas_utilizadas)
      end
      { posicoes:, resultados: }
    end

    def percorrer_estados(eventos, datas)
      ordenados = eventos_efetivos(eventos)
      posicoes = {}
      resultados = []
      chaves_utilizadas = Set.new
      caixas_utilizadas = Set.new
      indice = 0
      datas.each do |data|
        while indice < ordenados.length && ordenados[indice][:data_competencia] <= data
          aplicar_evento!(ordenados[indice], posicoes, resultados, chaves_utilizadas, caixas_utilizadas)
          indice += 1
        end
        yield data, posicoes, resultados
      end
    end

    def eventos_efetivos(eventos)
      alvos = eventos.select { |e| e[:tipo] == "reversao" }.map { |e| e[:alvo_id] }.compact.to_set
      eventos.reject { |e| e[:tipo] == "reversao" || e[:tombstone] || alvos.include?(e[:id]) }
        .sort_by { |e| [e[:data_competencia], e[:ordem] || 2**31, e[:id] || 2**62] }
    end

    def aplicar_evento!(evento, posicoes, resultados, chaves_utilizadas, caixas_utilizadas)
      registrar_uso_caixa!(evento, caixas_utilizadas)
      case evento[:tipo]
      when "nota_negociacao" then aplicar_nota!(evento, posicoes, resultados, chaves_utilizadas)
      when "saldo_inicial" then aplicar_saldo_inicial!(evento, posicoes, chaves_utilizadas)
      when "transferencia_custodia" then aplicar_transferencia_custodia!(evento, posicoes, chaves_utilizadas)
      when "evento_corporativo" then aplicar_evento_corporativo!(evento, posicoes, chaves_utilizadas)
      end
    end

    def registrar_uso_caixa!(evento, caixas_utilizadas)
      d = evento[:detalhe]
      if evento[:tipo] == "saldo_inicial_caixa"
        if caixas_utilizadas.include?(d[:conta_caixa_id])
          raise Financeiro::HistoricoInvalido.new(saldo_inicial_caixa: ["só pode inaugurar uma conta de caixa"],
            transacao_id: evento[:id], conta_caixa_id: d[:conta_caixa_id])
        end
        caixas_utilizadas << d[:conta_caixa_id]
      else
        [d[:conta_caixa_id], d[:conta_caixa_origem_id], d[:conta_caixa_destino_id]].compact.each do |caixa_id|
          caixas_utilizadas << caixa_id
        end
      end
    end

    def aplicar_nota!(evento, posicoes, resultados, chaves_utilizadas)

      detalhe = evento[:detalhe]
      conta_id = detalhe[:conta_investimento_id]
      detalhe[:negociacoes].sort_by { |n| n[:ordem] }.each do |n|
        chave = [conta_id, n[:ativo_id]]
        atual = posicoes[chave] ||= { conta_investimento_id: conta_id, ativo_id: n[:ativo_id], quantidade: BigDecimal("0"),
          custo_total_local: BigDecimal("0"), custo_total_base: BigDecimal("0"), ultima_transacao_id: evento[:id] }
        bruto = (n[:quantidade] * n[:preco_unitario]).round(12)
        if n[:natureza] == "compra"
          chaves_utilizadas << chave
          atual[:quantidade] += n[:quantidade]
          if atual[:custo_total_local]
            atual[:custo_total_local] += bruto + n[:custo_alocado]
            atual[:custo_total_base] += (bruto + n[:custo_alocado]) * detalhe[:taxa_conversao_base]
          end
        else
          if n[:quantidade] > atual[:quantidade]
            raise Financeiro::HistoricoInvalido.new(negociacoes: ["venda excede a posição disponível"], transacao_id: evento[:id], ativo_id: n[:ativo_id])
          end
          proporcao = n[:quantidade] / atual[:quantidade]
          custo_local = atual[:custo_total_local] && (atual[:custo_total_local] * proporcao).round(12)
          custo_base = atual[:custo_total_base] && (atual[:custo_total_base] * proporcao).round(12)
          alienacao_local = bruto
          custo_venda_local = n[:custo_alocado]
          alienacao_base = (alienacao_local * detalhe[:taxa_conversao_base]).round(12)
          custo_venda_base = (custo_venda_local * detalhe[:taxa_conversao_base]).round(12)
          resultados << { transacao_id: evento[:id], data: evento[:data_competencia], conta_investimento_id: conta_id,
            ativo_id: n[:ativo_id], quantidade: n[:quantidade], alienacao_local:, custo_removido_local: custo_local,
            custo_venda_local:, resultado_local: custo_local && alienacao_local - custo_local - custo_venda_local,
            alienacao_base:, custo_removido_base: custo_base,
            custo_venda_base:, resultado_base: custo_base && alienacao_base - custo_base - custo_venda_base }
          atual[:quantidade] -= n[:quantidade]
          atual[:custo_total_local] -= custo_local if custo_local
          atual[:custo_total_base] -= custo_base if custo_base
        end
        atual[:ultima_transacao_id] = evento[:id]
        if atual[:quantidade].zero?
          posicoes.delete(chave)
        else
          atual[:quantidade] = atual[:quantidade].round(10)
          atual[:custo_total_local] = atual[:custo_total_local]&.round(12)
          atual[:custo_total_base] = atual[:custo_total_base]&.round(12)
        end
      end
    end

    def aplicar_saldo_inicial!(evento, posicoes, chaves_utilizadas)
      d = evento[:detalhe]
      chave = [d[:conta_investimento_id], d[:ativo_id]]
      if chaves_utilizadas.include?(chave)
        raise Financeiro::HistoricoInvalido.new(saldo_inicial: ["só pode inaugurar uma posição"],
          transacao_id: evento[:id], ativo_id: d[:ativo_id])
      end
      chaves_utilizadas << chave
      posicoes[chave] = { conta_investimento_id: d[:conta_investimento_id], ativo_id: d[:ativo_id],
        quantidade: d[:quantidade], custo_total_local: d[:custo_total_local], custo_total_base: d[:custo_total_base],
        ultima_transacao_id: evento[:id] }
    end

    def aplicar_transferencia_custodia!(evento, posicoes, chaves_utilizadas)
      d = evento[:detalhe]
      origem_chave = [d[:conta_origem_id], d[:ativo_id]]
      destino_chave = [d[:conta_destino_id], d[:ativo_id]]
      origem = posicoes[origem_chave]
      if origem.nil? || d[:quantidade] > origem[:quantidade]
        raise Financeiro::HistoricoInvalido.new(transferencia_custodia: ["quantidade excede a posição de origem"],
          transacao_id: evento[:id], ativo_id: d[:ativo_id])
      end

      proporcao = d[:quantidade] / origem[:quantidade]
      custo_local = origem[:custo_total_local] && (origem[:custo_total_local] * proporcao).round(12)
      custo_base = origem[:custo_total_base] && (origem[:custo_total_base] * proporcao).round(12)
      origem[:quantidade] = (origem[:quantidade] - d[:quantidade]).round(10)
      origem[:custo_total_local] = (origem[:custo_total_local] - custo_local).round(12) if custo_local
      origem[:custo_total_base] = (origem[:custo_total_base] - custo_base).round(12) if custo_base
      origem[:ultima_transacao_id] = evento[:id]
      posicoes.delete(origem_chave) if origem[:quantidade].zero?

      destino = posicoes[destino_chave] ||= { conta_investimento_id: d[:conta_destino_id], ativo_id: d[:ativo_id],
        quantidade: BigDecimal("0"), custo_total_local: BigDecimal("0"), custo_total_base: BigDecimal("0"),
        ultima_transacao_id: evento[:id] }
      destino[:quantidade] = (destino[:quantidade] + d[:quantidade]).round(10)
      destino[:custo_total_local] = combinar_custo(destino[:custo_total_local], custo_local)
      destino[:custo_total_base] = combinar_custo(destino[:custo_total_base], custo_base)
      destino[:ultima_transacao_id] = evento[:id]
      chaves_utilizadas << destino_chave
    end

    def aplicar_evento_corporativo!(evento, posicoes, chaves_utilizadas)
      d = evento[:detalhe]
      origem_chave = [d[:conta_investimento_id], d[:ativo_origem_id]]
      origem = posicoes[origem_chave]
      unless origem
        raise Financeiro::HistoricoInvalido.new(evento_corporativo: ["não há posição no ativo de origem"],
          transacao_id: evento[:id], ativo_id: d[:ativo_origem_id])
      end

      if d[:tipo_evento].in?(%w[desdobramento grupamento bonificacao])
        if d[:tipo_evento].in?(%w[desdobramento bonificacao]) && d[:quantidade_final] <= origem[:quantidade]
          raise Financeiro::HistoricoInvalido.new(quantidade_final: ["deve aumentar a posição neste evento"], transacao_id: evento[:id])
        elsif d[:tipo_evento] == "grupamento" && d[:quantidade_final] >= origem[:quantidade]
          raise Financeiro::HistoricoInvalido.new(quantidade_final: ["deve reduzir a posição no grupamento"], transacao_id: evento[:id])
        end
        origem[:quantidade] = d[:quantidade_final]
        origem[:ultima_transacao_id] = evento[:id]
      else
        destino_chave = [d[:conta_investimento_id], d[:ativo_destino_id]]
        destino = posicoes[destino_chave] ||= { conta_investimento_id: d[:conta_investimento_id], ativo_id: d[:ativo_destino_id],
          quantidade: BigDecimal("0"), custo_total_local: BigDecimal("0"), custo_total_base: BigDecimal("0"),
          ultima_transacao_id: evento[:id] }
        destino[:quantidade] = (destino[:quantidade] + d[:quantidade_final]).round(10)
        destino[:custo_total_local] = combinar_custo(destino[:custo_total_local], origem[:custo_total_local])
        destino[:custo_total_base] = combinar_custo(destino[:custo_total_base], origem[:custo_total_base])
        destino[:ultima_transacao_id] = evento[:id]
        chaves_utilizadas << destino_chave
        posicoes.delete(origem_chave)
      end
    end

    def combinar_custo(atual, adicional)
      atual && adicional && (atual + adicional).round(12)
    end

    def lancamentos(d)
      if d[:negociacoes]
        valor = d[:negociacoes].sum do |n|
          bruto = n[:quantidade] * n[:preco_unitario]
          n[:natureza] == "venda" ? bruto : -bruto
        end - d[:custo_operacional_total]
        valor.zero? ? [] : [{ ordem: 1, conta_caixa_id: d[:conta_caixa_id], data_efetiva: d[:data_liquidacao], natureza: "liquidacao_nota", valor: valor.round(12) }]
      elsif d[:tipo_provento]
        d[:valor_liquido].zero? ? [] : [{ ordem: 1, conta_caixa_id: d[:conta_caixa_id], data_efetiva: d[:data_pagamento], natureza: "provento", valor: d[:valor_liquido] }]
      elsif d[:tipo_movimentacao]
        case d[:tipo_movimentacao]
        when "aporte" then [{ ordem: 1, conta_caixa_id: d[:conta_caixa_destino_id], data_efetiva: d[:data_efetiva], natureza: "aporte", valor: d[:valor_destino] }]
        when "resgate" then [{ ordem: 1, conta_caixa_id: d[:conta_caixa_origem_id], data_efetiva: d[:data_efetiva], natureza: "resgate", valor: -d[:valor_origem] }]
        when "transferencia" then [
          { ordem: 1, conta_caixa_id: d[:conta_caixa_origem_id], data_efetiva: d[:data_efetiva], natureza: "transferencia_saida", valor: -d[:valor_origem] },
          { ordem: 2, conta_caixa_id: d[:conta_caixa_destino_id], data_efetiva: d[:data_efetiva], natureza: "transferencia_entrada", valor: d[:valor_destino] }
        ]
        when "cambio" then [
          { ordem: 1, conta_caixa_id: d[:conta_caixa_origem_id], data_efetiva: d[:data_efetiva], natureza: "cambio_saida", valor: -d[:valor_origem] },
          { ordem: 2, conta_caixa_id: d[:conta_caixa_destino_id], data_efetiva: d[:data_efetiva], natureza: "cambio_entrada", valor: d[:valor_destino] }
        ]
        end
      elsif d.key?(:valor_saldo_inicial)
        [{ ordem: 1, conta_caixa_id: d[:conta_caixa_id], data_efetiva: d[:data_efetiva],
          natureza: "saldo_inicial", valor: d[:valor_saldo_inicial] }]
      else
        []
      end
    end

    def previa(tipo, d, ordem, estado)
      ls = lancamentos(d).map { |linha| Financeiro.congelar(linha.deep_dup) }.freeze
      posicoes = estado[:posicoes].values.map { |posicao| Financeiro.congelar(posicao.deep_dup) }.freeze
      PreviaTransacao.new(tipo:, data_competencia: d[:data_competencia], ordem_na_data: ordem,
        detalhe_normalizado: d, lancamentos: ls, liquidacao_liquida: ls.sum { |l| l[:valor] }, posicoes_resultantes: posicoes)
    end

    def substituir_lancamentos!(transacao, linhas)
      LancamentoCaixa.where(transacao_financeira_id: transacao.id).delete_all
      linhas.each { |linha| transacao.lancamentos_caixa.create!(linha) }
    end

    def reconstruir_posicoes!(investidor)
      estado = projetar(eventos_confirmados(investidor))
      conta_ids = investidor.carteiras.joins(:contas_investimento).pluck("contas_investimento.id")
      PosicaoAtual.where(conta_investimento_id: conta_ids).delete_all
      estado[:posicoes].each_value do |p|
        next unless p[:ultima_transacao_id]
        PosicaoAtual.create!(p)
      end
      estado
    end

    def com_bloqueios(investidor)
      TransacaoFinanceira.transaction do
        investidor.lock!
        investidor.carteiras.order(:id).lock.load
        yield
      end
    end

    def com_escrita_derivada
      chave = :carteiras_escrita_derivada_confirmada
      anterior = Thread.current[chave]
      Thread.current[chave] = true
      yield
    ensure
      Thread.current[chave] = anterior
    end

    def escrita_derivada_permitida?
      Thread.current[:carteiras_escrita_derivada_confirmada] == true
    end

    def validar_cardinalidade_detalhe!(transacao)
      presentes = []
      presentes << "nota_negociacao" if NotaNegociacao.where(transacao_financeira_id: transacao.id).exists?
      presentes << "provento" if Provento.where(transacao_financeira_id: transacao.id).exists?
      presentes << "movimentacao_caixa" if MovimentacaoCaixa.where(transacao_financeira_id: transacao.id).exists?
      presentes << "saldo_inicial" if SaldoInicial.where(transacao_financeira_id: transacao.id).exists?
      presentes << "saldo_inicial_caixa" if SaldoInicialCaixa.where(transacao_financeira_id: transacao.id).exists?
      presentes << "transferencia_custodia" if TransferenciaCustodia.where(transacao_financeira_id: transacao.id).exists?
      presentes << "evento_corporativo" if EventoCorporativo.where(transacao_financeira_id: transacao.id).exists?
      return if presentes == [transacao.tipo]

      raise Financeiro::AtributosInvalidos.new(detalhe: ["deve existir exatamente um detalhe compatível com o tipo"])
    end

    def validar_elegibilidade_reversao!(transacao)
      unless transacao.confirmada? && !transacao.reversao? && !transacao.revertida?
        raise Financeiro::EstadoInvalido.new(estado: ["transação não pode ser revertida ou corrigida"])
      end
    end

    def proxima_ordem(investidor, data)
      investidor.transacoes_financeiras.confirmadas.where(data_competencia: data).maximum(:ordem_na_data).to_i + 1
    end

    def caixa!(id, investidor)
      raise Financeiro::AtributosInvalidos.new(conta_caixa_id: ["deve ser um ID inteiro"]) unless id.is_a?(Integer)
      caixa = ContaCaixa.includes({ conta_investimento: { carteira: :investidor } }, :moeda).find_by(id:)
      raise Financeiro::EscopoInvalido.new(conta_caixa_id: ["não encontrado"]) unless caixa&.investidor&.id == investidor.id
      if caixa.arquivado? || caixa.conta_investimento.arquivado? || caixa.carteira.arquivado? || caixa.moeda.arquivado?
        raise Financeiro::RegistroArquivado.new(conta_caixa_id: ["está indisponível"])
      end
      caixa
    end

    def conta_investimento!(id, investidor)
      unless id.is_a?(Integer)
        raise Financeiro::AtributosInvalidos.new(conta_investimento_id: ["deve ser um ID inteiro"])
      end
      conta = ContaInvestimento.includes(carteira: :investidor).find_by(id:)
      unless conta&.investidor&.id == investidor.id
        raise Financeiro::EscopoInvalido.new(conta_investimento_id: ["não encontrada"])
      end
      if conta.arquivado? || conta.carteira.arquivado?
        raise Financeiro::RegistroArquivado.new(conta_investimento_id: ["está indisponível"])
      end
      conta
    end

    def ativo!(id)
      raise Financeiro::AtributosInvalidos.new(ativo_id: ["deve ser um ID inteiro"]) unless id.is_a?(Integer)
      Ativo.find_by(id:) || raise(Financeiro::EscopoInvalido.new(ativo_id: ["não encontrado"]))
    end

    def ativo_disponivel!(id)
      ativo = ativo!(id)
      raise Financeiro::RegistroArquivado.new(ativo_id: ["está arquivado"]) if ativo.arquivado?
      ativo
    end

    def validar_taxa_base!(caixa, taxa)
      base = caixa.carteira.moeda_base_id
      if caixa.moeda_id == base && taxa != 1
        raise Financeiro::AtributosInvalidos.new(taxa_conversao_base: ["deve ser 1 quando a moeda coincide com a base"])
      end
    end

    def decimal!(valor, campo, escala:, minimo: nil, minimo_exclusivo: nil)
      raise Financeiro::AtributosInvalidos.new(campo => ["deve ser uma string decimal"]) unless valor.is_a?(String)
      numero = BigDecimal(valor, exception: false)
      raise Financeiro::AtributosInvalidos.new(campo => ["é inválido"]) unless numero&.finite?
      numero = numero.round(escala)
      raise Financeiro::AtributosInvalidos.new(campo => ["é menor que o permitido"]) if minimo && numero < minimo
      raise Financeiro::AtributosInvalidos.new(campo => ["deve ser positivo"]) if minimo_exclusivo && numero <= minimo_exclusivo
      numero
    end

    def data!(valor, campo)
      return valor if valor.is_a?(Date)
      return Date.iso8601(valor) if valor.is_a?(String)
      raise ArgumentError
    rescue ArgumentError
      raise Financeiro::AtributosInvalidos.new(campo => ["deve ser uma data ISO válida"])
    end

    def ordem!(valor)
      return nil if valor.nil?
      raise Financeiro::AtributosInvalidos.new(ordem_na_data: ["deve ser um inteiro positivo"]) unless valor.is_a?(Integer) && valor.positive?
      valor
    end

    def texto_opcional(valor, campo)
      return nil if valor.nil?
      raise Financeiro::AtributosInvalidos.new(campo => ["deve ser texto"]) unless valor.is_a?(String)
      valor.strip.presence
    end

    def exigir_hash_simbolico!(valor)
      unless valor.is_a?(Hash) && valor.keys.all?(Symbol)
        raise Financeiro::AtributosInvalidos.new(payload: ["deve ser um hash com chaves simbólicas"])
      end
    end

    def validar_chaves!(hash, permitidas, opcionais: %i[observacao ordem_na_data])
      desconhecidas = hash.keys - permitidas
      ausentes = permitidas.reject { |k| opcionais.include?(k) || hash.key?(k) }
      detalhes = {}
      detalhes[:atributos_desconhecidos] = desconhecidas if desconhecidas.any?
      detalhes[:atributos_ausentes] = ausentes if ausentes.any?
      raise Financeiro::AtributosInvalidos.new(detalhes) if detalhes.any?
    end
  end
end
