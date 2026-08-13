require "digest"

module ImportacoesFinanceiras
  MAXIMO_ARQUIVOS = 20
  MAXIMO_BYTES = 25.megabytes
  VERSAO_PARSER = "1".freeze

  class << self
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
