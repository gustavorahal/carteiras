class ImportaAvenue < ImportaBase

  def self.importar(conta_corrente, file_path)
    sheet = Roo::Excelx.new(file_path).sheet(0)
    raise StandardError, 'Extrato em formato inválido' unless formato_correto?(sheet)

    h = sheet.row(1)
    valor_header = h[4]
    i = 2
    loop do
      row = sheet.row(i)
      break if row[0].blank?

      valor = _corrige_valor(valor_header, row[4])
      liquidacao = row[2]
      movimentacao = row[0]
      _insere_linha_extrato(conta_corrente, liquidacao, movimentacao, row[3], valor)
      i += 1
    end

  end

  def self._corrige_valor(valor_header, valor)
    # O celula do valor esta como string na planilha, e não objeto moeda portanto devemos
    # ajeitar o valor para formar en_US para pode ser "casteado" para float
    if valor_header == 'Valor (U$)'
      return valor.gsub('U$ ', '').gsub('.', '').gsub(',', '.').to_f
    elsif valor_header == 'Valor (R$)'
      return valor.gsub('R$ ', '').gsub('.', '').gsub(',', '.').to_f
    else
      raise StandardError, 'Não consigo corrigir valor da coluna Valor'
    end
  end

  def self.formato_correto?(sheet)
    # verifica se formato adequado
    h = sheet.row(1)
    h[0] == 'Data' && h[1] == 'Hora' && h[2] == 'Liquidação' && h[3] == 'Descrição' && (h[4] == 'Valor (U$)' || h[4] == 'Valor (R$)')
  end

end