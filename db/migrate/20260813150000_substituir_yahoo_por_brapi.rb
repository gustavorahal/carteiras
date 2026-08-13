class SubstituirYahooPorBrapi < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      INSERT INTO fontes_cotacao (codigo, nome, created_at, updated_at)
      SELECT 'BRAPI', 'brapi.dev', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      WHERE NOT EXISTS (SELECT 1 FROM fontes_cotacao WHERE codigo = 'BRAPI')
    SQL
    execute <<~SQL.squish
      UPDATE fontes_cotacao
      SET arquivado_em = COALESCE(arquivado_em, CURRENT_TIMESTAMP), updated_at = CURRENT_TIMESTAMP
      WHERE codigo = 'YAHOO'
    SQL

    remove_index :ativos, :simbolo_yahoo
    remove_column :ativos, :simbolo_yahoo
  end

  def down
    add_column :ativos, :simbolo_yahoo, :string
    add_index :ativos, :simbolo_yahoo
  end
end
