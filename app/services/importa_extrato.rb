class ImportaExtrato

  def self.extrato_xp(conta_corrente, file_path)
    xlsx = Roo::Excelx.new(file_path)
    sheet = xlsx.sheet(0)
    i = 16 # até o momento é onde começa o extrato
    extrato_file = []
    loop do
      row = sheet.row(i)
      break unless row[0].is_a? Date

      extrato_file.push row
      i += 1
    end

    extrato_atual = conta_corrente.extratos

    extrato_file.each do |linha|
      liquidacao = linha[0]
      movimentacao = linha[1]
      descricao = linha[2].gsub('* PROV * ', '')
      valor = linha[3]

      next unless extrato_atual.find_by(liquidacao: liquidacao,
                                        movimentacao: movimentacao,
                                        descricao: descricao,
                                        valor: valor).nil?

      Extrato.create(conta_corrente: conta_corrente,
                     liquidacao: liquidacao,
                     movimentacao: movimentacao,
                     descricao: descricao,
                     valor: valor)
    end
  end
end
