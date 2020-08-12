class CreateAtivos < ActiveRecord::Migration[6.0]
  def change
    create_table :ativos do |t|
      t.string :nome, unique: true
      t.string :descricao
      t.integer :tipo
      t.string :moeda

      t.timestamps
    end
  end
end
