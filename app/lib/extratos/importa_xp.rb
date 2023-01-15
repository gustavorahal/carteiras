module Extratos
  class ImportaXp < ImportaBase

    HEADER_ROW = 14
    MOV_ROW = 0
    LIQ_ROW = 1
    DESC_ROW = 2
    VALOR_ROW = 4
    SALDO_ROW = 5

    def self.importar(conta_corrente, file_path)
      sheet = Roo::Excelx.new(file_path).sheet(0)
      # verifica se formato adequado
      # linha 15 esta o header
      raise StandardError, 'Extrato em formato inválido' unless formato_correto?(sheet.row(HEADER_ROW))

      i = 15 # onde começa o extrato
      loop do
        row = sheet.row(i)
        break unless row[MOV_ROW].is_a? Date

        descricao = row[DESC_ROW].gsub('* PROV * ', '')
        _insere_linha_extrato(conta_corrente, row[LIQ_ROW], row[MOV_ROW], descricao, row[VALOR_ROW], row[SALDO_ROW])
        i += 1
      end
    end

    def self.formato_correto?(hr)
      hr[MOV_ROW] == 'Movimentação' && hr[LIQ_ROW] == 'Liquidação' && hr[DESC_ROW] == 'Lançamento' && hr[VALOR_ROW] == 'Valor (R$)'
    end

  end
end