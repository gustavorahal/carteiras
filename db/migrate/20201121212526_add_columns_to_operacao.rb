class AddColumnsToOperacao < ActiveRecord::Migration[6.0]
  def change
    add_reference :operacoes, :ativo, foreign_key: true
    add_reference :operacoes, :carteira, foreign_key: true
  end
end
