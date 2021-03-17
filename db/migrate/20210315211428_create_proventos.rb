class CreateProventos < ActiveRecord::Migration[6.0]
  def change
    create_table :proventos do |t|
      t.references :carteira, null: false, foreign_key: true
      t.references :ativo, null: false, foreign_key: true
      t.references :corretora, null: false, foreign_key: true
      t.references :extrato, foreign_key: true
      t.integer :evento, null: false
      t.float :quantidade, null: false
      t.float :valor_liquido, null: false
      t.string :moeda, null: false, default: 'BRL'
      t.date :data, null: false

      t.timestamps
    end
  end
end
