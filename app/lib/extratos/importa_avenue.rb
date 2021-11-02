module Extratos
  class ImportaAvenue < ImportaBase

    def self.importar(conta_corrente, file_path)
      sheet = CSV.table(file_path, headers: true, liberal_parsing: true)
      raise StandardError, 'Extrato em formato inválido' unless formato_correto?(sheet.headers)

      i = 0
      loop do
        row = sheet[i]
        break if row.blank?

        valor = _corrige_valor(row[4])
        liquidacao = row[2]
        movimentacao = row[0]
        descricao = row[3]
        _insere_linha_extrato(conta_corrente, liquidacao, movimentacao, descricao, valor, nil)
        i += 1
      end

    end

    def self._corrige_valor(valor)
      return valor if valor.is_a? Float
      # O valor no CSV vem no formato pt_BR e com prefixo da moeda
      # Remover moeda e converter para en_US
      valor.gsub('U$ ', '').gsub('R$ ', '').gsub('.', '').gsub(',', '.').to_f
    end

    def self.formato_correto?(hr)
      # verifica se formato adequado
      hr[0] == :data && hr[1] == :hora && hr[2] == :liquidao && hr[3] == :descrio && (hr[4] == :valor_r || hr[4] == :valor_u) || hr[5] == :saldo_da_conta
    end

  end
end