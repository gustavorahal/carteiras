module ImportacoesFinanceiras
  module Adapters
    class XpAntiga < BaseNota
      def self.reconhece?(texto)
        texto.match?(/NOTA DE (?:NEGOCIAÇÃO|CORRETAGEM)/) && texto.include?("XP INVESTIMENTOS")
      end

      def initialize(texto)
        @texto = texto
      end

      def extrair
        cabecalho = @texto.match(/Nr\. nota.*?Data pregão\s*\n\s*(\d+)\s+\d+\s+(\d{2}\/\d{2}\/\d{4})/m)
        raise Financeiro::AtributosInvalidos.new(layout: ["não foi possível localizar a nota XP antiga"]) unless cabecalho
        conta = @texto[/Cliente\s+.*?\n\s*(\d+)\s+/m, 1]
        linhas = @texto.lines.filter_map do |linha|
          next unless linha.match?(/^\s*\d+-BOVESPA\s+[CV]\s+(?:VISTA|FRACIONARIO)\s+/)
          negocio = linha.match(/^\s*\d+-BOVESPA\s+([CV])\s+(?:VISTA|FRACIONARIO)\s+(.+?)\s+([\d.]+(?:,\d+)?)\s+([\d.]+,\d+)\s+([\d.]+,\d{2})\s+[DC]\s*$/)
          next unless negocio
          descricao = negocio[2].squish
          { "ticker" => descricao[/\b[A-Z]{4}\d{1,2}\b/], "descricao" => descricao, "mercado" => "B3",
            "natureza" => negocio[1] == "C" ? "compra" : "venda",
            "quantidade" => numero(decimal_br(negocio[3])), "preco_unitario" => numero(decimal_br(negocio[4])) }
        end
        liquido = @texto.match(/L[ií]quido para\s+(\d{2}\/\d{2}\/\d{4})\s+([\d.]+,\d{2})\s+([DC])/)
        raise Financeiro::AtributosInvalidos.new(nota: ["não contém líquido de liquidação"]) unless liquido
        valor = decimal_br(liquido[2]) * (liquido[3] == "C" ? 1 : -1)
        nota = finalizar_nota(numero_nota: cabecalho[1], negociacao: data_br(cabecalho[2]), liquidacao: data_br(liquido[1]),
          moeda: "BRL", linhas:, liquido_informado: valor, conta_externa: conta)
        { "tipo_documento" => "notas_negociacao", "formato" => "xp_antiga", "notas" => [nota] }
      end
    end
  end
end
