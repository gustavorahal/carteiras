class AddIndexContaCorrente < ActiveRecord::Migration[6.0]
  def change
    add_index :conta_correntes, [:carteira_id, :corretora_id, :moeda],
              unique: true,
              name: 'index_cc_on_carteira_id_and_corretora_id_and_moeda'
  end
end
