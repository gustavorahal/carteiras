class ImportaExtrato

  def self.extrato_xp(investidor_id, file_path)
    xlsx = Roo::Excelx.new(file_path)
    corretora_xp = Corretora.find_by(nome: 'XP')
    sheet = xlsx.sheet(0)
    i = 16 # até o momento é onde começa o extrato
    extrato_file = []
    loop do
      row = sheet.row(i)
      break unless row[0].is_a? Date

      extrato_file.push row
      i += 1
    end

    extrato_atual = Extrato
                    .where(investidor_id: investidor_id,
                           corretora_id: corretora_xp.id)
                    .order(liquidacao: :desc)

    extrato_file.each do |linha|
      liquidacao = linha[0]
      movimentacao = linha[1]
      descricao = linha[2].gsub('* PROV * ', '')
      valor = linha[3]

      next unless extrato_atual.find_by(liquidacao: liquidacao,
                                        movimentacao: movimentacao,
                                        descricao: descricao,
                                        valor: valor).nil?

      Extrato.create(investidor_id: investidor_id,
                     corretora_id: corretora_xp.id,
                     liquidacao: liquidacao,
                     movimentacao: movimentacao,
                     descricao: descricao,
                     valor: valor, moeda: 'BRL')
    end
  end
end
