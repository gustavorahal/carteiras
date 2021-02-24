class AddCnpjToAtivos < ActiveRecord::Migration[6.0]
  def change
    add_column :ativos, :cnpj, :string
    add_index :ativos, :cnpj
  end
end
