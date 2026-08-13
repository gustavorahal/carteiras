module ImportacoesFinanceiras
  module Adapters
    class ExtratoAvenue
      def initialize(caminho)
        @caminho = caminho
      end

      def extrair
        tabela = CSV.read(@caminho, headers: true, col_sep: ";", encoding: "bom|utf-8")
        raise Financeiro::AtributosInvalidos.new(layout: ["extrato Avenue em formato desconhecido"]) if tabela.headers.size < 5
        itens = tabela.filter_map do |linha|
          next if linha[0].blank?
          { "data_movimentacao" => Date.parse(linha[0].to_s).iso8601,
            "data_liquidacao" => Date.parse((linha[2].presence || linha[0]).to_s).iso8601,
            "descricao" => linha[3].to_s.squish, "valor" => decimal_br(linha[4]),
            "saldo_informado" => linha[5].present? ? decimal_br(linha[5]) : nil,
            "identificador_externo" => identificador(linha), "moeda" => moeda(linha[4]),
            "estado_conciliacao" => "pendente" }
        end
        { "tipo_documento" => "extrato", "formato" => "extrato_avenue", "itens" => itens }
      end

      private

      def decimal_br(valor)
        BigDecimal(valor.to_s.gsub(/[^\d,.-]/, "").delete(".").tr(",", ".")).round(12).to_s("F")
      end

      def moeda(valor)
        valor.to_s.match?(/U\$|US\$|USD/i) ? "USD" : "BRL"
      end

      def identificador(linha)
        indice = linha.headers.index { |cabecalho| cabecalho.to_s.downcase.include?("identificador") }
        indice && linha[indice].presence
      end
    end
  end
end
