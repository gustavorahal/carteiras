class CreateContaCorrentes < ActiveRecord::Migration[6.0]
  def change
    create_table :conta_correntes do |t|
      t.references :investidor, null: false
      t.references :corretora, null: false
      t.string :moeda, null: false

      t.timestamps
    end

    add_index :conta_correntes, [:investidor_id, :corretora_id, :moeda],
              unique: true,
              name: 'index_cc_on_investidor_id_and_corretora_id_and_moeda'
  end
end
