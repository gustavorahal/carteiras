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
        raise Financeiro::AtributosInvalidos.new(fonte: ["deve ser YAHOO"]) unless fonte.codigo == "YAHOO"
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

    def buscar_e_registrar_yahoo(data:)
      data = Interno.data!(data)
      fonte = FonteCotacao.find_by!(codigo: "YAHOO")
      resultados = []
      falhas = []
      Ativo.ativos.where.not(simbolo_yahoo: [nil, ""]).find_each do |ativo|
        begin
          preco = Interno.buscar_yahoo(ativo.simbolo_yahoo, data)
          resultados << registrar_cotacao_ativo(ativo:, data:, preco: preco.to_s("F"), fonte:, manual: false)
        rescue StandardError => e
          Rails.logger.error("Yahoo #{ativo.simbolo_yahoo} em #{data}: #{e.class}: #{e.message}")
          falhas << "#{ativo.simbolo_yahoo}: #{e.message}"
        end
      end
      raise "falha ao buscar #{falhas.length} cotação(ões) Yahoo: #{falhas.join('; ')}" if falhas.any?

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

    def buscar_yahoo(simbolo, data, http: Net::HTTP)
      inicio = Time.utc(data.year, data.month, data.day).to_i
      fim = inicio + 86_400
      uri = URI("https://query1.finance.yahoo.com/v8/finance/chart/#{URI.encode_uri_component(simbolo)}?period1=#{inicio}&period2=#{fim}&interval=1d")
      resposta = if http == Net::HTTP
        conexao = http.new(uri.host, uri.port)
        conexao.use_ssl = true
        conexao.open_timeout = 5
        conexao.read_timeout = 10
        conexao.get(uri.request_uri)
      else
        http.get_response(uri)
      end
      raise "resposta HTTP #{resposta.code}" unless resposta.is_a?(Net::HTTPSuccess)
      json = JSON.parse(resposta.body)
      valor = json.dig("chart", "result", 0, "indicators", "quote", 0, "close", 0)
      numero = BigDecimal(valor.to_s, exception: false)
      raise "preço ausente ou inválido" unless numero&.finite? && numero.positive?
      numero.round(12)
    rescue JSON::ParserError => e
      raise "resposta inválida: #{e.message}"
    end
  end
end
