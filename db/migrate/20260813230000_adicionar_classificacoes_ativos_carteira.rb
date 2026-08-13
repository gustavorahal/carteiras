class AdicionarClassificacoesAtivosCarteira < ActiveRecord::Migration[8.1]
  def change
    create_table :classificacoes_ativos_carteira do |t|
      t.references :carteira, null: false, foreign_key: { on_delete: :restrict }
      t.references :ativo, null: false, foreign_key: { on_delete: :restrict }
      t.string :categoria, null: false

      t.timestamps
    end

    add_index :classificacoes_ativos_carteira, %i[carteira_id ativo_id], unique: true,
      name: "idx_classificacoes_ativos_carteira_unica"
    add_check_constraint :classificacoes_ativos_carteira,
      "categoria IN ('acoes', 'renda_fixa', 'internacional', 'commodities', 'fundos', 'outros')",
      name: "classificacoes_ativos_carteira_categoria_valida"
  end
end
