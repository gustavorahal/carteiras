require "net/http"
require "json"

module Mercado
  ResultadoCotacao = Data.define(:cotacao, :estado)

  class << self
    def registrar_cotacao_ativo(ativo:, data:, preco:, fonte:, manual:, usuario: nil)
      raise Financeiro::RegistroArquivado.new(ativo: ["está arquivado"]) if ativo.arquivado?
      raise Financeiro::RegistroArquivado.new(fonte: ["está arquivada"]) if fonte.arquivado?
      data = Interno.data!(data)
      preco = Interno.decimal!(preco, :preco)
      if manual
        Interno.autorizar_admin!(usuario)
        raise Financeiro::AtributosInvalidos.new(fonte: ["deve ser MANUAL"]) unless fonte.codigo == "MANUAL"
      else
        raise Financeiro::AtributosInvalidos.new(fonte: ["deve ser BRAPI"]) unless fonte.codigo == "BRAPI"
        raise Financeiro::AtributosInvalidos.new(usuario: ["deve ser ausente na automação"]) if usuario
      end

      CotacaoAtivo.transaction do
        cotacao = CotacaoAtivo.lock.find_or_initialize_by(ativo:, data:)
        return ResultadoCotacao.new(cotacao:, estado: "ignorada_manual") if !manual && cotacao.persisted? && cotacao.manual?

        estado = cotacao.new_record? ? "criada" : "atualizada"
        cotacao.assign_attributes(preco:, fonte_cotacao: fonte, manual:, autor: manual ? usuario : nil)
        cotacao.save!
        ResultadoCotacao.new(cotacao:, estado:)
      end
    end

    def registrar_cotacao_cambio(moeda_origem:, moeda_destino:, data:, taxa:, usuario:)
      Interno.autorizar_admin!(usuario)
      fonte = FonteCotacao.find_by!(codigo: "MANUAL")
      if moeda_origem.arquivado? || moeda_destino.arquivado? || fonte.arquivado?
        raise Financeiro::RegistroArquivado.new(catalogo: ["está arquivado"])
      end
      data = Interno.data!(data)
      taxa = Interno.decimal!(taxa, :taxa)
      raise Financeiro::AtributosInvalidos.new(moedas: ["devem ser distintas"]) if moeda_origem == moeda_destino

      cotacao = CotacaoCambio.find_or_initialize_by(moeda_origem:, moeda_destino:, data:)
      estado = cotacao.new_record? ? "criada" : "atualizada"
      cotacao.update!(taxa:, fonte_cotacao: fonte, autor: usuario)
      ResultadoCotacao.new(cotacao:, estado:)
    end

    def liberar_automacao(cotacao_ativo:, usuario:)
      Interno.autorizar_admin!(usuario)
      cotacao_ativo.update!(manual: false, autor: nil)
      cotacao_ativo
    end

    def buscar_e_registrar_brapi(data:)
      data = Interno.data!(data)
      fonte = FonteCotacao.find_by!(codigo: "BRAPI")
      token = Interno.token_brapi!
      resultados = []
      falhas = []
      Ativo.ativos.where(mercado: "B3").find_each do |ativo|
        begin
          preco = Interno.buscar_brapi(ativo.codigo, data, token:)
          unless preco
            Rails.logger.info("brapi sem cotação para #{ativo.codigo} em #{data}")
            next
          end
          resultados << registrar_cotacao_ativo(ativo:, data:, preco: preco.to_s("F"), fonte:, manual: false)
        rescue StandardError => e
          Rails.logger.error("brapi #{ativo.codigo} em #{data}: #{e.class}: #{e.message}")
          falhas << "#{ativo.codigo}: #{e.message}"
        end
      end
      raise "falha ao buscar #{falhas.length} cotação(ões) brapi: #{falhas.join('; ')}" if falhas.any?

      resultados.freeze
    end
  end

  module Interno
    module_function

    def autorizar_admin!(usuario)
      raise Financeiro::NaoAutorizado unless usuario&.administrador_sistema?
    end

    def decimal!(valor, campo)
      raise Financeiro::AtributosInvalidos.new(campo => ["deve ser uma string decimal"]) unless valor.is_a?(String)
      numero = BigDecimal(valor, exception: false)
      numero = numero&.round(12)
      raise Financeiro::AtributosInvalidos.new(campo => ["deve ser positivo"]) unless numero&.finite? && numero.positive?
      numero
    end

    def data!(valor)
      return valor if valor.is_a?(Date)
      Date.iso8601(valor.to_s)
    rescue ArgumentError
      raise Financeiro::AtributosInvalidos.new(data: ["inválida"])
    end

    def token_brapi!
      token = ENV["BRAPI_API_TOKEN"].presence || Rails.application.credentials.dig(:brapi, :api_token).presence
      raise "BRAPI_API_TOKEN não configurado" unless token

      token
    end

    def buscar_brapi(simbolo, data, token:, http: Net::HTTP)
      uri = URI("https://brapi.dev/api/v2/stocks/historical")
      uri.query = URI.encode_www_form(symbols: simbolo, startDate: data.iso8601, endDate: data.iso8601, interval: "1d")
      requisicao = Net::HTTP::Get.new(uri)
      requisicao["Authorization"] = "Bearer #{token}"
      resposta = if http == Net::HTTP
        conexao = http.new(uri.host, uri.port)
        conexao.use_ssl = true
        conexao.open_timeout = 5
        conexao.read_timeout = 10
        conexao.request(requisicao)
      else
        http.request(uri, requisicao)
      end
      return if resposta.is_a?(Net::HTTPNotFound)

      raise "resposta HTTP #{resposta.code}" unless resposta.is_a?(Net::HTTPSuccess)
      json = JSON.parse(resposta.body)
      resultado = json.fetch("results", []).find { |item| item["requestedSymbol"].to_s.casecmp?(simbolo) }
      historico = resultado&.dig("data", "historicalDataPrice") || []
      ponto = historico.find do |item|
        timestamp = Integer(item["date"], exception: false)
        timestamp && Time.at(timestamp).in_time_zone("Brasilia").to_date == data
      end
      valor = ponto&.fetch("close", nil)
      return if valor.nil?

      numero = BigDecimal(valor.to_s, exception: false)
      raise "preço ausente ou inválido" unless numero&.finite? && numero.positive?
      numero.round(12)
    rescue JSON::ParserError => e
      raise "resposta inválida: #{e.message}"
    end
  end
end
