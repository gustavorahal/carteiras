class ImportaXp < ImportaBase

  def self.importar(conta_corrente, file_path)
    sheet = Roo::Excelx.new(file_path).sheet(0)
    raise StandardError, 'Extrato em formato inválido' unless formato_correto?(sheet)

    i = 16 # onde começa o extrato
    loop do
      row = sheet.row(i)
      break unless row[0].is_a? Date

      descricao = row[2].gsub('* PROV * ', '')
      _insere_linha_extrato(conta_corrente, row[0], row[1], descricao, row[3])
      i += 1
    end
  end

  def self.formato_correto?(sheet)
    # verifica se formato adequado
    # linha 15 esta o header
    h = sheet.row(15)
    h[0] == 'Liq' && h[1] == 'Mov' && h[3] == 'Valor' && h[4] == 'Saldo'
  end

end