class RemoveCarteiraAtivo < ActiveRecord::Migration[6.0]
  def change
    remove_column :operacoes, :carteira_ativo_id
    drop_table :carteira_ativos
  end
end
