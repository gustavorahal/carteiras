require "csv"
require "open3"

module ImportacoesFinanceiras
  module Interno
    module_function

    def caminho(arquivo)
      valor = arquivo.respond_to?(:path) ? arquivo.path : arquivo.to_s
      raise Financeiro::AtributosInvalidos.new(arquivo: ["não existe"]) unless File.file?(valor)
      valor
    end

    def nome(arquivo, caminho)
      arquivo.respond_to?(:original_filename) ? arquivo.original_filename.to_s : File.basename(caminho)
    end

    def tamanho(arquivo)
      File.size(caminho(arquivo))
    end

    def extrair(caminho, nome, conta)
      extensao = File.extname(nome).downcase
      case extensao
      when ".pdf"
        texto = extrair_texto_pdf(caminho)
        adapter_pdf(texto).new(texto).extrair
      when ".xlsx"
        Adapters::ExtratoXp.new(caminho).extrair
      when ".csv"
        Adapters::ExtratoAvenue.new(caminho).extrair
      else
        raise Financeiro::AtributosInvalidos.new(formato: ["arquivo não suportado"])
      end.then { |dados| resolver_referencias!(dados, conta) }
    end

    def extrair_texto_pdf(caminho)
      texto, erro, status = Open3.capture3("pdftotext", "-layout", caminho, "-")
      unless status.success? && texto.present?
        raise Financeiro::AtributosInvalidos.new(pdf: [erro.presence || "não foi possível extrair texto"])
      end
      texto
    rescue Errno::ENOENT
      raise Financeiro::AtributosInvalidos.new(pdf: ["pdftotext não está instalado"])
    end

    def adapter_pdf(texto)
      return Adapters::XpAtual if Adapters::XpAtual.reconhece?(texto)
      return Adapters::XpAntiga if Adapters::XpAntiga.reconhece?(texto)
      return Adapters::AvenueAtual if Adapters::AvenueAtual.reconhece?(texto)
      return Adapters::AvenueDriveWealth if Adapters::AvenueDriveWealth.reconhece?(texto)

      raise Financeiro::AtributosInvalidos.new(layout: ["PDF não corresponde a um layout XP ou Avenue conhecido"])
    end

    def resolver_referencias!(dados, conta)
      if dados["tipo_documento"] == "notas_negociacao"
        Array(dados["notas"]).each do |nota|
          Array(nota["negociacoes"]).each do |negociacao|
            next if negociacao["ativo_id"].present?
            ticker = negociacao["ticker"].to_s.upcase.presence
            mercado = negociacao["mercado"].presence
            candidatos = ticker ? Ativo.ativos.where("UPPER(codigo) = ?", ticker) : Ativo.none
            candidatos = candidatos.where(mercado:) if mercado
            negociacao["ativo_id"] = candidatos.pick(:id) if candidatos.one?
          end
          conta_documento = normalizar_identificador(nota["conta_externa"])
          conta_selecionada = normalizar_identificador(conta.identificador_externo)
          nota["conta_externa_divergente"] = conta_documento != conta_selecionada if conta_documento && conta_selecionada
          resolver_caixa_e_cambio!(nota, conta)
        end
      elsif dados["tipo_documento"] == "extrato"
        Array(dados["itens"]).each do |item|
          moeda = Moeda.find_by(codigo: item["moeda"].to_s.upcase)
          caixa = moeda && conta.contas_caixa.ativos.find_by(moeda:)
          item["conta_caixa_id"] = caixa&.id
        end
      end
      dados
    end

    def resolver_caixa_e_cambio!(nota, conta)
      moeda = Moeda.find_by(codigo: nota["moeda"].to_s.upcase)
      caixa = moeda && conta.contas_caixa.ativos.find_by(moeda:)
      nota["conta_caixa_id"] = caixa&.id
      return unless moeda && caixa

      base = conta.carteira.moeda_base
      if moeda == base
        nota["taxa_conversao_base"] = "1"
      else
        cotacao = CotacaoCambio.where(moeda_origem: moeda, moeda_destino: base, data: ..Date.iso8601(nota.fetch("data_liquidacao")))
          .order(data: :desc).first
        inversa = CotacaoCambio.where(moeda_origem: base, moeda_destino: moeda, data: ..Date.iso8601(nota.fetch("data_liquidacao")))
          .order(data: :desc).first unless cotacao
        nota["taxa_conversao_base"] = if cotacao
          cotacao.taxa.to_s("F")
        elsif inversa
          (BigDecimal("1") / inversa.taxa).round(12).to_s("F")
        end
      end
    end

    def aplicar_resolucoes!(dados, resolucoes)
      resolucoes.to_h.deep_stringify_keys.each do |chave, valor|
        next if valor.blank?
        case chave
        when /\Anota\.(\d+)\.negociacao\.(\d+)\.ativo_id\z/
          dados.fetch("notas").fetch(Regexp.last_match(1).to_i).fetch("negociacoes").fetch(Regexp.last_match(2).to_i)["ativo_id"] = Integer(valor)
        when /\Anota\.(\d+)\.taxa_conversao_base\z/
          dados.fetch("notas").fetch(Regexp.last_match(1).to_i)["taxa_conversao_base"] = decimal_string(valor)
        when /\Anota\.(\d+)\.custo\.(\d+)\z/
          dados.fetch("notas").fetch(Regexp.last_match(1).to_i).fetch("negociacoes").fetch(Regexp.last_match(2).to_i)["custo_alocado"] = decimal_string(valor)
        end
      end
      dados
    rescue ArgumentError, IndexError, KeyError
      raise Financeiro::AtributosInvalidos.new(resolucoes: ["contêm uma referência inválida"])
    end

    def pendencias(dados)
      pendencias = []
      if dados["tipo_documento"] == "notas_negociacao"
        Array(dados["notas"]).each_with_index do |nota, ni|
          if nota["conta_externa_divergente"]
            pendencias << pendencia("nota.#{ni}.conta_externa",
              "a conta #{nota['conta_externa']} do documento difere da conta de investimento selecionada")
          end
          pendencias << pendencia("nota.#{ni}.conta_caixa_id", "não há conta de caixa para #{nota['moeda']}") unless nota["conta_caixa_id"]
          pendencias << pendencia("nota.#{ni}.taxa_conversao_base", "informe o câmbio da nota #{nota['numero']}") unless nota["taxa_conversao_base"].present?
          Array(nota["negociacoes"]).each_with_index do |negociacao, li|
            unless negociacao["ativo_id"]
              rotulo = negociacao["ticker"].presence || negociacao["descricao"]
              pendencias << pendencia("nota.#{ni}.negociacao.#{li}.ativo_id", "selecione o ativo para #{rotulo}")
            end
          end
        end
      else
        Array(dados["itens"]).each_with_index do |item, indice|
          pendencias << pendencia("item.#{indice}.conta_caixa_id", "não há conta de caixa para #{item['moeda']}") unless item["conta_caixa_id"]
        end
      end
      pendencias
    end

    def criar_notas!(importacao, dados, usuario)
      dados.fetch("notas").each_with_index.map do |nota, indice|
        negociacoes = nota.fetch("negociacoes").map do |linha|
          atributos = { ativo_id: Integer(linha.fetch("ativo_id")), natureza: linha.fetch("natureza"),
            quantidade: linha.fetch("quantidade"), preco_unitario: linha.fetch("preco_unitario") }
          atributos[:custo_alocado] = linha["custo_alocado"] if linha.key?("custo_alocado")
          atributos
        end
        atributos = { conta_caixa_id: Integer(nota.fetch("conta_caixa_id")),
          data_negociacao: nota.fetch("data_negociacao"), data_liquidacao: nota.fetch("data_liquidacao"),
          custo_operacional_total: nota.fetch("custo_operacional_total"),
          taxa_conversao_base: nota.fetch("taxa_conversao_base"), negociacoes:,
          observacao: "Importada de #{importacao.nome_original}; líquido informado #{nota['liquido_informado']} #{nota['moeda']}" }
        chave = "nota:#{importacao.checksum_sha256}:#{nota.fetch('numero')}:#{indice + 1}"
        TransacoesFinanceiras.criar_rascunho(tipo: "nota_negociacao", investidor: importacao.investidor,
          usuario:, atributos:, chave_idempotencia: chave, origem: "importacao", importacao:)
      end
    end

    def conciliar_extrato!(importacao, dados, usuario)
      usados = ids_lancamentos_ja_vinculados(importacao.id)
      criadas = []
      dados.fetch("itens").each_with_index do |item, indice|
        caixa = ContaCaixa.find(item.fetch("conta_caixa_id"))
        data = Date.iso8601(item.fetch("data_liquidacao"))
        valor = BigDecimal(item.fetch("valor"))
        candidatos = LancamentoCaixa.where(conta_caixa: caixa, valor:, data_efetiva: (data - 3.days)..(data + 3.days))
          .where.not(id: usados).to_a
        if candidatos.one?
          item["estado_conciliacao"] = "conciliado"
          item["lancamento_caixa_id"] = candidatos.first.id
          usados << candidatos.first.id
        elsif candidatos.many?
          item["estado_conciliacao"] = "ambiguo"
        elsif (tipo = classificacao_inequivoca(item["descricao"], valor))
          atributos = { tipo_movimentacao: tipo,
            (tipo == "aporte" ? :conta_caixa_destino_id : :conta_caixa_origem_id) => caixa.id,
            valor: valor.abs.to_s("F"), data_efetiva: data }
          transacao = TransacoesFinanceiras.criar_rascunho(tipo: "movimentacao_caixa", investidor: importacao.investidor,
            usuario:, atributos:, chave_idempotencia: "extrato:#{importacao.checksum_sha256}:#{indice + 1}",
            origem: "importacao", importacao:)
          item["estado_conciliacao"] = "rascunho_criado"
          item["transacao_financeira_id"] = transacao.id
          criadas << transacao
        else
          item["estado_conciliacao"] = "ambiguo"
        end
      end
      criadas
    end

    def ids_lancamentos_ja_vinculados(importacao_id)
      ImportacaoFinanceira.where.not(id: importacao_id).pluck(:dados_extraidos).flat_map do |dados|
        Array(dados["itens"]).filter_map { |item| item["lancamento_caixa_id"] }
      end.to_set
    end

    def classificacao_inequivoca(descricao, valor)
      texto = descricao.to_s.downcase
      return "aporte" if valor.positive? && texto.match?(/aporte|dep[oó]sito|transfer[eê]ncia recebida/)
      return "resgate" if valor.negative? && texto.match?(/resgate|retirada|transfer[eê]ncia enviada/)
    end

    def decimal_string(valor)
      numero = BigDecimal(valor.to_s.tr(",", "."), exception: false)
      raise ArgumentError unless numero&.finite?
      numero.round(12).to_s("F")
    end

    def normalizar_identificador(valor)
      valor.to_s.upcase.gsub(/[^A-Z0-9]/, "").presence
    end

    def pendencia(campo, mensagem)
      { "campo" => campo, "mensagem" => mensagem }
    end

    def resumir_erro(erro)
      mensagem = erro.respond_to?(:detalhes) ? erro.detalhes.values.flatten.join(", ") : erro.message
      mensagem.to_s.squish.truncate(500)
    end
  end
end
