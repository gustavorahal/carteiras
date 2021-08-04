module Extratos
  class ImportaVitreo < ImportaBase

    def self.importar(conta_corrente, file_path)
      # Load a csv and auto-strip the BOM (byte order mark)
      # csv files saved from MS Excel typically have the BOM marker at the beginning of the file
      sheet = Roo::Excelx.new(file_path).sheet(0)
      raise StandardError, 'Extrato em formato inválido' unless formato_correto?(sheet)

      i = 1
      loop do
        i += 1
        row = sheet.row(i)
        break if row[0].blank?
        descricao = row[3].gsub('* PROV * ', '')

        # vitreo não mantem consistência dos valores da coluna de saldo, sendo eles recalculados
        # sem muita consistência portanto não inseri-los e portanto não considera-los
        _insere_linha_extrato(conta_corrente, row[1], row[0], descricao, row[4], nil)
      end
    end

    def self.formato_correto?(sheet)
      # verifica se formato adequado
      h = sheet.row(1)
      h[0] == 'Movimentação' && h[1] == 'Liquidação' &&
        h[2] == 'Tipo' && h[3] == 'Descrição' &&
        h[4] == 'Valor de transação' && h[5] == 'Saldo'
    end

  end
end