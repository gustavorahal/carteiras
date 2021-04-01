class ImportaVitreo < ImportaBase

  def self.importar(conta_corrente, file_path)
    # Load a csv and auto-strip the BOM (byte order mark)
    # csv files saved from MS Excel typically have the BOM marker at the beginning of the file
    sheet = Roo::CSV.new(file_path, csv_options: { col_sep: ';', encoding: 'bom|utf-8' } )
    raise StandardError, 'Extrato em formato inválido' unless formato_correto?(sheet)

    i = 1
    loop do
      i += 1
      row = sheet.row(i)
      break if row[0].blank?
      next if row[2] == 'SALDO DO DIA'

      _insere_linha_extrato(conta_corrente, row[0], row[0], row[2], row[3], row[4])
    end
  end

  def self.formato_correto?(sheet)
    # verifica se formato adequado
    h = sheet.row(1)
    h[0] == 'DataMovimentacao' && h[1] == 'Tipo' && 
      h[2] == 'DescricaoLancamento' && h[3] == 'ValorLancamento' &&
      h[4] == 'Saldo'
  end

end