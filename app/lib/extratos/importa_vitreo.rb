module Extratos
  class ImportaVitreo < ImportaBase

    def self.importar(conta_corrente, file_path)
      sheet = Roo::Excelx.new(file_path).sheet(0)
      raise StandardError, 'Extrato em formato inválido' unless formato_correto?(sheet.row(1))

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

    def self.formato_correto?(hr)
      # verifica se formato adequado
      hr[0] == 'Movimentação' && hr[1] == 'Liquidação' &&
        hr[2] == 'Tipo' && hr[3] == 'Descrição' &&
        hr[4] == 'Valor de transação' && hr[5] == 'Saldo'
    end

  end
end