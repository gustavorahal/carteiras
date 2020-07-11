class CreateCarteiraAtivos < ActiveRecord::Migration[6.0]
  def change
    create_table :carteira_ativos do |t|
      t.references :carteira, null: false, foreign_key: true
      t.references :ativo, null: false, foreign_key: true
      t.references :investidor, null: false, foreign_key: true
      t.string :book
      t.float :porcentagem

      t.timestamps
    end
  end
end
