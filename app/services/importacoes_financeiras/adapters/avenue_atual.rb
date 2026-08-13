module ImportacoesFinanceiras
  module Adapters
    class AvenueAtual < BaseNota
      def self.reconhece?(texto)
        texto.include?("Apex Clearing Corporation") && texto.include?("Account Number")
      end

      def initialize(texto)
        @texto = texto
      end

      def extrair
        conta = @texto[/Account Number:\s*([^\s]+)/, 1]
        linhas = @texto.lines.filter_map do |linha|
          negocio = linha.match(/^\s*1\s+([BS])\s+(\d{2}\/\d{2}\/\d{2})\s+(\d{2}\/\d{2}\/\d{2})\s+([\d.]+)\s+([A-Z.]+)\s+([\d,.]+)\s+([\d,.]+)\s+([\d,.]+)\s+([\d,.]+)\s+([\d,.]+)\s+\S+\s+([\d,.]+)/)
          next unless negocio
          custo = decimal_us(negocio[8]) + decimal_us(negocio[9]) + decimal_us(negocio[10])
          natureza = negocio[1] == "B" ? "compra" : "venda"
          liquido = decimal_us(negocio[11])
          { "ticker" => negocio[5], "descricao" => negocio[5], "mercado" => "EUA",
            "natureza" => natureza, "quantidade" => numero(decimal_us(negocio[4])),
            "preco_unitario" => numero(decimal_us(negocio[6])), "custo_alocado" => numero(custo),
            "data_negociacao" => data_us_curta(negocio[2]), "data_liquidacao" => data_us_curta(negocio[3]),
            "principal" => decimal_us(negocio[7]),
            "liquido_informado" => natureza == "venda" ? liquido : -liquido }
        end
        raise Financeiro::AtributosInvalidos.new(nota: ["não contém negócios Avenue reconhecíveis"]) if linhas.empty?
        grupos = linhas.group_by { |linha| [linha.delete("data_negociacao"), linha.delete("data_liquidacao")] }
        notas = grupos.map.with_index do |((negociacao, liquidacao), grupo), indice|
          custo = grupo.sum { |linha| BigDecimal(linha.fetch("custo_alocado")) }
          bruto = grupo.sum do |linha|
            valor = linha.delete("principal")
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
        { "tipo_documento" => "notas_negociacao", "formato" => "avenue_atual", "notas" => notas }
      end
    end
  end
end
