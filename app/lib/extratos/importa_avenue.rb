module Extratos
  class ImportaAvenue < ImportaBase

    def self.importar(conta_corrente, file_path)
      sheet = Roo::Excelx.new(file_path).sheet(0)
      raise StandardError, 'Extrato em formato inválido' unless formato_correto?(sheet)

      i = 2
      loop do
        row = sheet.row(i)
        break if row[0].blank?

        valor = _corrige_valor(row[4])
        liquidacao = row[2]
        movimentacao = row[0]
        saldo = _corrige_valor(row[5])
        _insere_linha_extrato(conta_corrente, liquidacao, movimentacao, row[3], valor, saldo)
        i += 1
      end

    end

    def self._corrige_valor(valor)
      # Para extrato em BRL, o Excel em portugues converte o valor sinalizado em R$ para um valor float
      # portanto nada a se fazer.
      return valor if valor.is_a? Float
      # Para extrato em USD, o Excel em portugues mantem o valor monetario como string.
      # O celula do valor esta como string na planilha, e não objeto moeda portanto devemos
      # ajeitar o valor para formar en_US para pode ser "casteado" para float
      # De qualquer maneira não podemos confiar na consistencia do comportamento do Excel, portanto
      # checar de qualquer maneira

      raise StandardError("Valor #{valor} não é String") unless valor.is_a?(String)

      if valor.include?('U$')
        return valor.gsub('U$ ', '').gsub('.', '').gsub(',', '.').to_f
      elsif valor.include?('R$')
        return valor.gsub('R$ ', '').gsub('.', '').gsub(',', '.').to_f
      else
        raise StandardError, "Não consigo corrigir valor #{valor}"
      end
    end

    def self.formato_correto?(sheet)
      # verifica se formato adequado
      h = sheet.row(1)
      h[0] == 'Data' && h[1] == 'Hora' && h[2] == 'Liquidação' && h[3] == 'Descrição' && (h[4] == 'Valor (U$)' || h[4] == 'Valor (R$)') || h[5] == 'Saldo da conta'
    end

  end
end