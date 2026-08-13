require "digest"

module ImportacoesFinanceiras
  MAXIMO_ARQUIVOS = 20
  MAXIMO_BYTES = 25.megabytes
  VERSAO_PARSER = "1".freeze
  ConciliacaoDTO = Data.define(:importacao_id, :itens_extrato, :saldos, :posicoes)

  class << self
    def conciliacao(importacao:, usuario:)
      autorizar_leitura!(importacao, usuario)
      dados = importacao.dados_extraidos
      itens_extrato = Financeiro.congelar(Array(dados["itens"]).deep_dup)
      saldos_informados = itens_extrato.group_by { |item| item["moeda"] }.transform_values do |itens|
        itens.each_with_index.select { |item, _indice| item["saldo_informado"].present? }
          .max_by { |item, indice| [Date.iso8601(item.fetch("data_liquidacao")), indice] }&.first
      end
      saldos = importacao.conta_investimento.contas_caixa.includes(:moeda).map do |caixa|
        item_saldo = saldos_informados[caixa.moeda.codigo]
        data_saldo = item_saldo && Date.iso8601(item_saldo.fetch("data_liquidacao"))
        calculado = if data_saldo
          caixa.lancamentos_caixa.where(data_efetiva: ..data_saldo).sum(:valor)
        else
          caixa.lancamentos_caixa.sum(:valor)
        end
        informado = item_saldo && BigDecimal(item_saldo.fetch("saldo_informado"))
        Financeiro.congelar({ conta_caixa_id: caixa.id, moeda: caixa.moeda.codigo, data_saldo:,
          calculado:, informado:, diferenca: informado && (calculado - informado).round(12) })
      end.freeze

      informadas = Array(dados["posicoes_informadas"]).index_by { |item| item["ativo_id"] }
      posicoes = importacao.conta_investimento.posicoes_atuais.joins(:ativo).includes(:ativo).order("ativos.codigo").map do |posicao|
        informada = informadas[posicao.ativo_id]&.dig("quantidade")&.then { |quantidade| BigDecimal(quantidade) }
        Financeiro.congelar({ ativo_id: posicao.ativo_id, ativo: posicao.ativo.codigo,
          informado: informada, calculado: posicao.quantidade,
          diferenca: informada && (posicao.quantidade - informada).round(10) })
      end.freeze

      ConciliacaoDTO.new(importacao_id: importacao.id, itens_extrato:, saldos:, posicoes:)
    end

    def analisar(arquivos:, conta:, usuario:)
      autorizar!(conta, usuario)
      arquivos = Array(arquivos).compact
      if arquivos.empty? || arquivos.size > MAXIMO_ARQUIVOS
        raise Financeiro::AtributosInvalidos.new(arquivos: ["envie entre 1 e #{MAXIMO_ARQUIVOS} arquivos"])
      end
      if arquivos.sum { |arquivo| Interno.tamanho(arquivo) } > MAXIMO_BYTES
        raise Financeiro::AtributosInvalidos.new(arquivos: ["o total deve ter no máximo 25 MB"])
      end

      arquivos.map { |arquivo| analisar_um(arquivo, conta, usuario) }
    end

    def criar_rascunhos(importacao:, usuario:, resolucoes: {})
      autorizar!(importacao.conta_investimento, usuario)
      raise Financeiro::EstadoInvalido.new(estado: ["a importação falhou"]) if importacao.estado == "falhou"
      raise Financeiro::EstadoInvalido.new(estado: ["a importação já foi concluída"]) if importacao.estado == "concluida"

      dados = importacao.dados_extraidos.deep_dup
      Interno.aplicar_resolucoes!(dados, resolucoes)
      Interno.resolver_referencias!(dados, importacao.conta_investimento)
      pendencias = Interno.pendencias(dados)
      unless pendencias.empty?
        importacao.update!(estado: "analisada", dados_extraidos: dados.merge("pendencias" => pendencias))
        raise Financeiro::AtributosInvalidos.new(pendencias: pendencias.map { |p| p["mensagem"] })
      end

      transacoes = ImportacaoFinanceira.transaction do
        criadas = if dados["tipo_documento"] == "extrato"
          Interno.conciliar_extrato!(importacao, dados, usuario)
        else
          Interno.criar_notas!(importacao, dados, usuario)
        end
        pendencias_finais = if dados["tipo_documento"] == "extrato"
          Array(dados["itens"]).each_with_index.filter_map do |item, indice|
            if item["estado_conciliacao"] == "ambiguo"
              { "campo" => "item.#{indice}", "mensagem" => "conciliação ambígua: #{item['descricao']}" }
            end
          end
        else
          []
        end
        importacao.update!(estado: pendencias_finais.empty? ? "concluida" : "analisada",
          dados_extraidos: dados.merge("pendencias" => pendencias_finais))
        criadas
      end
      transacoes
    end

    def confirmar_em_lote(importacoes:, usuario:)
      transacoes = Array(importacoes).flat_map do |importacao|
        autorizar!(importacao.conta_investimento, usuario)
        unless importacao.estado == "concluida" && importacao.pendencias.empty?
          raise Financeiro::EstadoInvalido.new(estado: ["todas as importações precisam estar concluídas e sem pendências"])
        end
        importacao.transacoes_financeiras.where(estado: "rascunho")
      end
      transacoes.sort_by { |t| [t.data_competencia, t.ordem_na_data || 2**31, t.id] }.map do |transacao|
        TransacoesFinanceiras.confirmar(transacao:, usuario:)
      end
    end

    private

    def autorizar_leitura!(importacao, usuario)
      raise Financeiro::NaoAutorizado unless usuario&.pode_ler?(importacao.investidor.espaco)
      unless importacao.conta_investimento.investidor.id == importacao.investidor_id
        raise Financeiro::EscopoInvalido.new(importacao_financeira: ["conta não pertence ao investidor"])
      end
    end

    def analisar_um(arquivo, conta, usuario)
      caminho = Interno.caminho(arquivo)
      checksum = Digest::SHA256.file(caminho).hexdigest
      existente = conta.importacoes_financeiras.find_by(checksum_sha256: checksum)
      nome = Interno.nome(arquivo, caminho)
      return existente if existente && (existente.versao_parser == VERSAO_PARSER || existente.transacoes_financeiras.exists?)

      importacao = existente || conta.importacoes_financeiras.create!(investidor: conta.investidor, autor: usuario,
        nome_original: nome, checksum_sha256: checksum, formato: "detectando",
        versao_parser: VERSAO_PARSER, estado: "pendente")
      if existente
        importacao.update!(autor: usuario, nome_original: nome, formato: "detectando",
          versao_parser: VERSAO_PARSER, estado: "pendente", dados_extraidos: {}, erro_resumido: nil)
      end
      resultado = Interno.extrair(caminho, nome, conta)
      importacao.update!(formato: resultado.fetch("formato"), estado: "analisada",
        dados_extraidos: resultado.merge("pendencias" => Interno.pendencias(resultado)), erro_resumido: nil)
      importacao
    rescue ActiveRecord::RecordNotUnique
      conta.importacoes_financeiras.find_by!(checksum_sha256: checksum)
    rescue StandardError => erro
      raise unless importacao&.persisted?

      importacao.update!(estado: "falhou", formato: "desconhecido",
        dados_extraidos: {}, erro_resumido: Interno.resumir_erro(erro))
      importacao
    end

    def autorizar!(conta, usuario)
      raise Financeiro::NaoAutorizado unless usuario&.pode_editar?(conta.espaco)
      if conta.arquivado? || conta.carteira.arquivado? || conta.investidor.arquivado? || conta.espaco.arquivado?
        raise Financeiro::RegistroArquivado.new(conta_investimento: ["está indisponível"])
      end
    end
  end
end
