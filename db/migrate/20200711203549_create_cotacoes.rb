class CreateCotacoes < ActiveRecord::Migration[6.0]
  def change
    create_table :cotacoes do |t|
      t.references :ativo, null: false, foreign_key: true
      t.float :valor_unit
      t.date :data, { null: false }

      t.timestamps
    end
  end
end
