module Extratos
  class ImportaXp < ImportaBase

    def self.importar(conta_corrente, file_path)
      sheet = Roo::Excelx.new(file_path).sheet(0)
      # verifica se formato adequado
      # linha 15 esta o header
      raise StandardError, 'Extrato em formato inválido' unless formato_correto?(sheet.row(15))

      i = 16 # onde começa o extrato
      loop do
        row = sheet.row(i)
        break unless row[0].is_a? Date

        descricao = row[2].gsub('* PROV * ', '')
        _insere_linha_extrato(conta_corrente, row[0], row[1], descricao, row[3], row[4])
        i += 1
      end
    end

    def self.formato_correto?(hr)
      hr[0] == 'Liq' && hr[1] == 'Mov' && hr[3] == 'Valor' && hr[4] == 'Saldo'
    end

  end
end