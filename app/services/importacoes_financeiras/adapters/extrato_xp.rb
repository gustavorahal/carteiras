require "roo"

module ImportacoesFinanceiras
  module Adapters
    class ExtratoXp
      def initialize(caminho)
        @caminho = caminho
      end

      def extrair
        planilha = Roo::Excelx.new(@caminho).sheet(0)
        cabecalho = planilha.row(14)
        unless cabecalho[0, 3] == ["Movimentação", "Liquidação", "Lançamento"] && cabecalho[4] == "Valor (R$)"
          raise Financeiro::AtributosInvalidos.new(layout: ["extrato XP em formato desconhecido"])
        end
        itens = []
        linha = 15
        while planilha.cell(linha, 1).present?
          itens << { "data_movimentacao" => data(planilha.cell(linha, 1)).iso8601,
            "data_liquidacao" => data(planilha.cell(linha, 2) || planilha.cell(linha, 1)).iso8601,
            "descricao" => planilha.cell(linha, 3).to_s.delete_prefix("* PROV * ").squish,
            "valor" => numero(planilha.cell(linha, 5)), "saldo_informado" => numero_opcional(planilha.cell(linha, 6)),
            "moeda" => "BRL", "estado_conciliacao" => "pendente" }
          linha += 1
        end
        { "tipo_documento" => "extrato", "formato" => "extrato_xp", "itens" => itens }
      end

      private

      def data(valor)
        valor.respond_to?(:to_date) ? valor.to_date : Date.parse(valor.to_s)
      end

      def numero(valor)
        BigDecimal(valor.to_s).round(12).to_s("F")
      end

      def numero_opcional(valor)
        valor.present? ? numero(valor) : nil
      end
    end
  end
end
