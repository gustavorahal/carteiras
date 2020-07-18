class CreateExtratos < ActiveRecord::Migration[6.0]
  def change
    create_table :extratos do |t|
      t.references :investidor, null: false, foreign_key: true
      t.string :corretora, { null: false }
      t.date :liquidacao, { null: false }
      t.date :movimentacao, { null: false }
      t.string :descricao, { null: false }
      t.float :valor, { null: false }
      t.string :moeda, { null: false }

      t.timestamps
    end
  end
end
