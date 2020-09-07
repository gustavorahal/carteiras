class RemoveColumnsOfExtratos < ActiveRecord::Migration[6.0]
  def change

    Extrato.distinct.pluck(:investidor_id, :corretora_id, :moeda).each do |investidor_id, corretora_id, moeda|
      ContaCorrente.create!(investidor_id: investidor_id,
                            corretora_id: corretora_id,
                            moeda: moeda)
    end

    Extrato.all.each do |ex|
      cc = ContaCorrente.find_by(investidor_id: ex.investidor_id,
                            corretora_id: ex.corretora_id,
                            moeda: ex.moeda)
      ex.conta_corrente = cc
      ex.save!
    end

    change_column_null :extratos, :conta_corrente_id, false
    remove_column :extratos, :investidor_id
    remove_column :extratos, :corretora_id
    remove_column :extratos, :moeda
  end
end
