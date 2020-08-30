class AddUniqueIndexToCarteiraAtivos < ActiveRecord::Migration[6.0]
  def change
    add_index :carteira_ativos, [:ativo_id, :carteira_id, :corretora_id],
              unique: true,
              name: 'index_ca_on_ativo_id_and_carteira_id_and_corretora_id'
  end
end
