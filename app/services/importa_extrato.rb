class ImportaExtrato

  def self.importar(conta_corrente, file_path)
    case conta_corrente.corretora.nome
    when 'XP'
      _xp(conta_corrente, file_path)
    when 'Avenue'
      _avenue(conta_corrente, file_path)
    else
      raise StandardError, 'Corretora não suportada'
    end
  end


  private_class_method def self._avenue(conta_corrente, file_path)
    sheet = Roo::Excelx.new(file_path).sheet(0)

    # verifica se formato adequado
    header = sheet.row(1)
    raise StandardError, 'Extrato em formato inválido' unless
        header[0] == 'Data' &&
        header[1] == 'Hora' &&
        header[2] == 'Liquidação' &&
        header[3] == 'Descrição' &&
        header[4] == 'Valor (U$)'

    i = 2
    loop do
      row = sheet.row(i)
      break if row[0].blank?

      # O celula do valor esta como string na planilha, e não objeto moeda portanto devemos
      # ajeitar o valor para formar en_US para pode ser "casteado" para float
      valor = row[4].gsub('U$ ', '').gsub('.', '').gsub(',', '.')
      _insere_linha_extrato(conta_corrente, row[2], row[0], row[3], valor)
      i += 1
    end

  end

  private_class_method def self._xp(conta_corrente, file_path)
    sheet = Roo::Excelx.new(file_path).sheet(0)

    # verifica se formato adequado
    # linha 15 esta o header
    header = sheet.row(15)
    raise StandardError, 'Extrato em formato inválido' unless
        header[0] == 'Liq' &&
        header[1] == 'Mov' &&
        header[3] == 'Valor' &&
        header[4] == 'Saldo'

    i = 16 # onde começa o extrato
    loop do
      row = sheet.row(i)
      break unless row[0].is_a? Date

      descricao = row[2].gsub('* PROV * ', '')
      _insere_linha_extrato(conta_corrente, row[0], row[1], descricao, row[3])
      i += 1
    end
  end

  private_class_method def self._insere_linha_extrato(conta_corrente, liquidacao, movimentacao, descricao, valor)
    extrato_atual = conta_corrente.extratos
    Rails.logger.debug("Inserindo na conta_corrente ##{conta_corrente.id} -> #{liquidacao}, #{movimentacao}, #{descricao}, #{valor}")
    return unless extrato_atual.find_by(liquidacao: liquidacao,
                                        movimentacao: movimentacao,
                                        descricao: descricao,
                                        valor: valor).nil?

    Extrato.create!(conta_corrente: conta_corrente,
                    liquidacao: liquidacao,
                    movimentacao: movimentacao,
                    descricao: descricao,
                    valor: valor)
  end

end
