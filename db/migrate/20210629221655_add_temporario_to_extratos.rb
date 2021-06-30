class AddTemporarioToExtratos < ActiveRecord::Migration[6.1]
  def up
    add_column :extratos, :temporario, :boolean, default: false
    change_column_null :extratos, :temporario, false
  end
  def down
    remove_column :extratos, :temporario
  end
end
