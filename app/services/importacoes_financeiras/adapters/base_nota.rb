module ImportacoesFinanceiras
  module Adapters
    class BaseNota
      private

      def decimal_br(valor)
        BigDecimal(valor.to_s.delete(".").tr(",", "."))
      end

      def decimal_us(valor)
        BigDecimal(valor.to_s.delete(","))
      end

      def decimal_monetario_us(valor)
        texto = valor.to_s.strip
        negativo = texto.start_with?("(") || texto.start_with?("-")
        numero = decimal_us(texto.gsub(/[^\d.]/, ""))
        negativo ? -numero : numero
      end

      def data_br(valor)
        Date.strptime(valor, "%d/%m/%Y")
      end

      def data_us_curta(valor)
        Date.strptime(valor, "%m/%d/%y")
      end

      def numero(valor)
        valor.round(12).to_s("F")
      end

      def finalizar_nota(numero_nota:, negociacao:, liquidacao:, moeda:, linhas:, liquido_informado:, conta_externa:)
        raise Financeiro::AtributosInvalidos.new(nota: ["não contém negócios reconhecíveis"]) if linhas.empty?
        bruto_assinado = linhas.sum do |linha|
          bruto = BigDecimal(linha.fetch("quantidade")) * BigDecimal(linha.fetch("preco_unitario"))
          linha["natureza"] == "venda" ? bruto : -bruto
        end
        custo = (bruto_assinado - liquido_informado).round(12)
        if custo.negative? && custo.abs <= BigDecimal("0.02")
          custo = BigDecimal("0")
        elsif custo.negative?
          raise Financeiro::AtributosInvalidos.new(nota: ["líquido informado é incompatível com os negócios"])
        end
        {
          "numero" => numero_nota.to_s,
          "data_negociacao" => negociacao.iso8601,
          "data_liquidacao" => liquidacao.iso8601,
          "moeda" => moeda,
          "conta_externa" => conta_externa,
          "negociacoes" => linhas,
          "bruto" => numero(bruto_assinado),
          "custo_operacional_total" => numero(custo),
          "liquido_calculado" => numero(bruto_assinado - custo),
          "liquido_informado" => numero(liquido_informado),
          "diferenca" => numero((bruto_assinado - custo) - liquido_informado)
        }
      end
    end
  end
end
