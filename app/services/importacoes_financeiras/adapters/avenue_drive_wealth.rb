module ImportacoesFinanceiras
  module Adapters
    class AvenueDriveWealth < BaseNota
      def self.reconhece?(texto)
        texto.include?("Avenue Securities") && texto.include?("DriveWealth") && texto.include?("Transaction")
      end

      def initialize(texto)
        @texto = texto
      end

      def extrair
        conta = @texto[/Account Number:\s*(.+?)\s+Account Name:/, 1]&.squish || @texto[/Account Number:\s*([^\n]+)/, 1]&.squish
        matches = []
        padrao = /^\s*([A-Z.]+)\s+(.+?)\s+C\s+(Buy|Sell)\s+(-?[\d.]+)\s+([\d,.]+)\s+(\d{1,2}\/\d{1,2}\/\d{4})\s+(\d{1,2}\/\d{1,2}\/\d{4})\s+(?:Agent|Principal)\s*$/
        @texto.to_enum(:scan, padrao).each { matches << Regexp.last_match.dup }
        raise Financeiro::AtributosInvalidos.new(nota: ["não contém negócios DriveWealth reconhecíveis"]) if matches.empty?

        linhas = matches.each_with_index.map do |match, indice|
          trecho = @texto[match.end(0)...(matches[indice + 1]&.begin(0) || @texto.length)]
          comissao = valor_rotulo(trecho, "Commission or Equivalent")
          transacao = valor_rotulo(trecho, "Transaction Fee")
          outros = valor_rotulo(trecho, "Other Fees / Credits")
          liquido_documento = valor_monetario_rotulo(trecho, "Net Amount")
          natureza = match[3] == "Buy" ? "compra" : "venda"
          { "ticker" => match[1], "descricao" => match[2].squish, "mercado" => "EUA",
            "natureza" => natureza, "quantidade" => numero(decimal_us(match[4]).abs),
            "preco_unitario" => numero(decimal_us(match[5])), "custo_alocado" => numero(comissao + transacao + outros),
            "data_negociacao" => Date.strptime(match[6], "%m/%d/%Y"),
            "data_liquidacao" => Date.strptime(match[7], "%m/%d/%Y"),
            "liquido_informado" => natureza == "venda" ? liquido_documento.abs : -liquido_documento.abs }
        end
        grupos = linhas.group_by { |linha| [linha.delete("data_negociacao"), linha.delete("data_liquidacao")] }
        notas = grupos.map.with_index do |((negociacao, liquidacao), grupo), indice|
          custo = grupo.sum { |linha| BigDecimal(linha.fetch("custo_alocado")) }
          bruto = grupo.sum do |linha|
            valor = BigDecimal(linha.fetch("quantidade")) * BigDecimal(linha.fetch("preco_unitario"))
            linha["natureza"] == "venda" ? valor : -valor
          end
          liquido = grupo.sum { |linha| linha.delete("liquido_informado") }
          nota = finalizar_nota(numero_nota: "#{negociacao.strftime('%Y%m%d')}-#{indice + 1}", negociacao:, liquidacao:,
            moeda: "USD", linhas: grupo, liquido_informado: liquido, conta_externa: conta)
          nota["custo_operacional_total"] = numero(custo)
          nota["liquido_calculado"] = numero(bruto - custo)
          nota["diferenca"] = numero((bruto - custo) - liquido)
          nota
        end
        { "tipo_documento" => "notas_negociacao", "formato" => "avenue_drivewealth", "notas" => notas }
      end

      private

      def valor_rotulo(trecho, rotulo)
        valor = trecho[/#{Regexp.escape(rotulo)}\s+\$?([\d,.]+)/, 1]
        valor ? decimal_us(valor) : BigDecimal("0")
      end

      def valor_monetario_rotulo(trecho, rotulo)
        valor = trecho[/#{Regexp.escape(rotulo)}\s+(\(?-?\$?[\d,.]+\)?)/, 1]
        raise Financeiro::AtributosInvalidos.new(nota: ["não contém #{rotulo}"]) unless valor

        decimal_monetario_us(valor)
      end
    end
  end
end
