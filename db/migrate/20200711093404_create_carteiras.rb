class CreateCarteiras < ActiveRecord::Migration[6.0]
  def change
    create_table :carteiras do |t|
      t.references :investidor, null: false, foreign_key: true
      t.string :nome

      t.timestamps
    end
  end
end
