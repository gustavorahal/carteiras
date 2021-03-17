class AddProcessadoToExtratos < ActiveRecord::Migration[6.0]
  def change
    add_column :extratos, :processado, :boolean, default: false
  end
end
