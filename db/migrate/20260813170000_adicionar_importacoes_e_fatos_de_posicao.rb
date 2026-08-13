class AdicionarImportacoesEFatosDePosicao < ActiveRecord::Migration[8.1]
  def change
    create_table :importacoes_financeiras do |t|
      t.references :investidor, null: false, foreign_key: { on_delete: :restrict }
      t.references :conta_investimento, null: false,
        foreign_key: { to_table: :contas_investimento, on_delete: :restrict }
      t.references :autor, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.string :nome_original, null: false
      t.string :checksum_sha256, null: false
      t.string :formato, null: false
      t.string :versao_parser, null: false
      t.string :estado, null: false, default: "pendente"
      t.jsonb :dados_extraidos, null: false, default: {}
      t.text :erro_resumido
      t.timestamps
    end
    add_index :importacoes_financeiras, %i[conta_investimento_id checksum_sha256], unique: true,
      name: "idx_importacoes_financeiras_checksum"
    add_check_constraint :importacoes_financeiras,
      "estado IN ('pendente', 'analisada', 'concluida', 'falhou')",
      name: "importacoes_financeiras_estado_valido"

    add_reference :transacoes_financeiras, :importacao_financeira,
      foreign_key: { to_table: :importacoes_financeiras, on_delete: :restrict }

    create_table :saldos_iniciais do |t|
      t.references :transacao_financeira, null: false,
        foreign_key: { to_table: :transacoes_financeiras, on_delete: :restrict }, index: { unique: true }
      t.references :conta_investimento, null: false,
        foreign_key: { to_table: :contas_investimento, on_delete: :restrict }
      t.references :ativo, null: false, foreign_key: { on_delete: :restrict }
      t.decimal :quantidade, precision: 30, scale: 10, null: false
      t.decimal :custo_total_local, precision: 30, scale: 12, null: false
      t.decimal :custo_total_base, precision: 30, scale: 12, null: false
      t.timestamps
    end
    add_check_constraint :saldos_iniciais,
      "quantidade > 0 AND custo_total_local >= 0 AND custo_total_base >= 0",
      name: "saldos_iniciais_valores_validos"

    create_table :transferencias_custodia do |t|
      t.references :transacao_financeira, null: false,
        foreign_key: { to_table: :transacoes_financeiras, on_delete: :restrict }, index: { unique: true }
      t.references :conta_origem, null: false,
        foreign_key: { to_table: :contas_investimento, on_delete: :restrict }
      t.references :conta_destino, null: false,
        foreign_key: { to_table: :contas_investimento, on_delete: :restrict }
      t.references :ativo, null: false, foreign_key: { on_delete: :restrict }
      t.decimal :quantidade, precision: 30, scale: 10, null: false
      t.timestamps
    end
    add_check_constraint :transferencias_custodia,
      "conta_origem_id <> conta_destino_id AND quantidade > 0",
      name: "transferencias_custodia_valores_validos"

    create_table :eventos_corporativos do |t|
      t.references :transacao_financeira, null: false,
        foreign_key: { to_table: :transacoes_financeiras, on_delete: :restrict }, index: { unique: true }
      t.string :tipo, null: false
      t.references :conta_investimento, null: false,
        foreign_key: { to_table: :contas_investimento, on_delete: :restrict }
      t.references :ativo_origem, null: false,
        foreign_key: { to_table: :ativos, on_delete: :restrict }
      t.references :ativo_destino,
        foreign_key: { to_table: :ativos, on_delete: :restrict }
      t.decimal :quantidade_final, precision: 30, scale: 10, null: false
      t.timestamps
    end
    add_check_constraint :eventos_corporativos,
      "tipo IN ('desdobramento', 'grupamento', 'bonificacao', 'conversao', 'incorporacao')",
      name: "eventos_corporativos_tipo_valido"
    add_check_constraint :eventos_corporativos, "quantidade_final > 0",
      name: "eventos_corporativos_quantidade_valida"
    add_check_constraint :eventos_corporativos,
      "(tipo IN ('desdobramento', 'grupamento', 'bonificacao') AND ativo_destino_id IS NULL) OR " \
        "(tipo IN ('conversao', 'incorporacao') AND ativo_destino_id IS NOT NULL AND ativo_destino_id <> ativo_origem_id)",
      name: "eventos_corporativos_ativos_validos"

    remove_check_constraint :transacoes_financeiras,
      "tipo IN ('nota_negociacao', 'provento', 'movimentacao_caixa', 'reversao')",
      name: "transacoes_tipo_valido"
    remove_check_constraint :transacoes_financeiras,
      "origem IN ('manual', 'sistema')",
      name: "transacoes_origem_valida"
    add_check_constraint :transacoes_financeiras,
      "tipo IN ('nota_negociacao', 'provento', 'movimentacao_caixa', 'saldo_inicial', " \
        "'transferencia_custodia', 'evento_corporativo', 'reversao')",
      name: "transacoes_tipo_valido"
    add_check_constraint :transacoes_financeiras,
      "origem IN ('manual', 'importacao', 'sistema')",
      name: "transacoes_origem_valida"
  end
end
