class AddMoedaExposicaoToAtivos < ActiveRecord::Migration[6.1]
  def change
    change_column_null :ativos, :moeda, false
    rename_column :ativos, :moeda, :moeda_negociacao

    add_column :ativos, :moeda_exposicao, :string
  end
end
