module Extratos
# A partir de um arquivo de extrato da corretora, por exemplo em formato
# xls ou csv, importar para dentro do BD para a tabela extratos
  class ImportaBase

    def self.importar(conta_corrente, file_path)
      raise NotImplementedError
    end

    def self.formato_correto?(header_row)
      raise NotImplementedError
    end

    def self._insere_linha_extrato(conta_corrente, liquidacao, movimentacao, descricao, valor, saldo)
      valor = Utils.decimal(valor)
      saldo = Utils.decimal(saldo)

      extrato_atual = conta_corrente.extratos
      return unless extrato_atual.find_by(liquidacao: liquidacao,
                                          movimentacao: movimentacao,
                                          descricao: descricao,
                                          valor: valor,
                                          saldo: saldo).nil?

      Rails.logger.info("Inserindo na conta_corrente ##{conta_corrente.id} -> #{liquidacao}, #{movimentacao}, #{descricao}, #{valor}, #{saldo}")
      Extrato.create!(conta_corrente: conta_corrente,
                      liquidacao: liquidacao,
                      movimentacao: movimentacao,
                      descricao: descricao,
                      valor: valor,
                      saldo: saldo)
    end

  end
end
