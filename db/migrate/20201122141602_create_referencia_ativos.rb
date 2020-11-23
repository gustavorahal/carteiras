class CreateReferenciaAtivos < ActiveRecord::Migration[6.0]
  def change
    create_table :referencia_ativos do |t|
      t.references :referencia, null: false, foreign_key: true
      t.references :ativo, null: false, foreign_key: true
      t.string :book, null: false
      t.float :porcentagem, null: false, default: 0
      t.date :data_entrada, null: false, default: -> { 'NOW()' }
      t.date :data_saida

      t.timestamps
    end

    add_index :referencia_ativos, [:referencia_id, :ativo_id], unique: true

  end
end
