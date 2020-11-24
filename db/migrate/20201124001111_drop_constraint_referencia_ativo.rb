class DropConstraintReferenciaAtivo < ActiveRecord::Migration[6.0]
  def change
    remove_index :referencia_ativos, column: [:referencia_id, :ativo_id]
  end
end
