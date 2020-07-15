class CreateExtratos < ActiveRecord::Migration[6.0]
  def change
    create_table :extratos do |t|
      t.references :investidor, null: false, foreign_key: true
      t.string :corretora
      t.date :liquidacao
      t.date :movimentacao
      t.string :descricao
      t.float :valor
      t.string :moeda

      t.timestamps
    end
  end
end
