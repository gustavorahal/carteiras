module ImportacoesFinanceiras
  module Adapters
    class XpAtual < BaseNota
      def self.reconhece?(texto)
        texto.match?(/Nota de (?:Negociação|Corretagem)/) && texto.include?("Conta XP") && texto.include?("Data de Referência")
      end

      def initialize(texto)
        @texto = texto
      end

      def extrair
        marcadores = []
        @texto.to_enum(:scan, /^\s*(\d{2}\/\d{2}\/\d{4})\s+(\d{6,})\s*$/).each do
          marcadores << [Regexp.last_match.begin(0), Regexp.last_match(1), Regexp.last_match(2)]
        end
        if marcadores.empty? && @texto.include?("Data pregão:")
          data = @texto[/Data pregão:.*?\n\s*(\d{2}\/\d{2}\/\d{4})\s*$/m, 1]
          marcadores << [0, data, "sem-numero-#{data.to_s.delete('/')}" ] if data
        end
        raise Financeiro::AtributosInvalidos.new(layout: ["não foi possível localizar as notas XP"]) if marcadores.empty?
        conta = @texto[/Conta XP\s+(\d+)/, 1]
        notas = marcadores.each_with_index.map do |(inicio, data, numero_nota), indice|
          trecho = @texto[inicio...(marcadores[indice + 1]&.first || @texto.length)]
          montar_nota(trecho, data, numero_nota, conta)
        end
        { "tipo_documento" => "notas_negociacao", "formato" => "xp_atual", "notas" => notas }
      end

      private

      def montar_nota(trecho, data, numero_nota, conta)
        linhas = trecho.lines.filter_map do |linha|
          next unless linha.match?(/^\s*(?:N\s+)?\d+-BOVESPA\s+[CV]\s+(?:VISTA|FRACIONARIO|VIS|FRA)\s+/)
          cabecalho = linha.match(/^\s*(?:N\s+)?\d+-BOVESPA\s+([CV])\s+(?:VISTA|FRACIONARIO|VIS|FRA)\s+(.+?)\s+([\d.]+(?:,\d+)?)\s+([\d.]+,\d+)\s+([\d.]+,\d{2})\s+[DC]\s*$/)
          next unless cabecalho
          descricao = cabecalho[2].squish
          ticker = descricao[/\b[A-Z]{4}\d{1,2}\b/]
          { "ticker" => ticker, "descricao" => descricao, "mercado" => "B3",
            "natureza" => cabecalho[1] == "C" ? "compra" : "venda",
            "quantidade" => numero(decimal_br(cabecalho[3])), "preco_unitario" => numero(decimal_br(cabecalho[4])) }
        end
        liquido = trecho.match(/L[ií]quido para\s+(\d{2}\/\d{2}\/\d{4})\s+([\d.]+,\d{2})\s+([DC])/)
        raise Financeiro::AtributosInvalidos.new(nota: ["não contém líquido de liquidação"]) unless liquido
        valor = decimal_br(liquido[2]) * (liquido[3] == "C" ? 1 : -1)
        finalizar_nota(numero_nota:, negociacao: data_br(data), liquidacao: data_br(liquido[1]), moeda: "BRL",
          linhas:, liquido_informado: valor, conta_externa: conta)
      end
    end
  end
end
