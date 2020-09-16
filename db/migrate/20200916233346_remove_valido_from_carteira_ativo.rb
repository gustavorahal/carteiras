class RemoveValidoFromCarteiraAtivo < ActiveRecord::Migration[6.0]
  def change
    remove_column :carteira_ativos, :valido
  end
end
