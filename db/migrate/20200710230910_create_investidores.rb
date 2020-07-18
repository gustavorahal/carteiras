class CreateInvestidores < ActiveRecord::Migration[6.0]
  def change
    create_table :investidores do |t|
      t.string :nome, { null: false }

      t.timestamps
    end
  end
end
