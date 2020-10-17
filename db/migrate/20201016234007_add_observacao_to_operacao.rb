class AddObservacaoToOperacao < ActiveRecord::Migration[6.0]
  def change
    add_column :operacoes, :observacao, :string
  end
end
