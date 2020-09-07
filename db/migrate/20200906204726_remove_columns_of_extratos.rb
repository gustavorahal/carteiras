class RemoveColumnsOfExtratos < ActiveRecord::Migration[6.0]
  def change
    change_column_null :extratos, :conta_corrente_id, false
    remove_column :extratos, :investidor_id
    remove_column :extratos, :corretora_id
    remove_column :extratos, :moeda
  end
end
