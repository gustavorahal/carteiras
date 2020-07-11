class CreateInvestidores < ActiveRecord::Migration[6.0]
  def change
    create_table :investidores do |t|
      t.string :nome

      t.timestamps
    end
  end
end
