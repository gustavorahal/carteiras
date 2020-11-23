class CreateReferencias < ActiveRecord::Migration[6.0]
  def change
    create_table :referencias do |t|
      t.string :nome, unique: true, null: false
      t.string :descricao

      t.timestamps
    end
  end
end
