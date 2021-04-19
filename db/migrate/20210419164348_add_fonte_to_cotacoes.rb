class AddFonteToCotacoes < ActiveRecord::Migration[6.1]
  def change
    add_column :cotacoes, :fonte, :integer
  end
end
