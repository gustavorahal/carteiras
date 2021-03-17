class CreateMovimentacoes < ActiveRecord::Migration[6.0]
  def change
    create_table :movimentacoes do |t|
      t.references :carteira, null: false, foreign_key: true
      t.references :corretora, null: false, foreign_key: true
      t.references :extrato, foreign_key: true
      t.float :valor, null: false
      t.string :moeda, null: false, default: 'BRL'
      t.date :data, null: false

      t.timestamps
    end
  end
end
