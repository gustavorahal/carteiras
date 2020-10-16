class ChangeDataCotacao < ActiveRecord::Migration[6.0]
  def change
    change_column :cotacoes, :data, :date
    change_column_null :cotacoes, :data, false
  end

  add_index :cotacoes, [:ativo_id, :data], unique: true
end
