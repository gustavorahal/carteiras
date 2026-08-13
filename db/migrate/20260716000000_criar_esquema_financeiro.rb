class CriarEsquemaFinanceiro < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.integer :sign_in_count, null: false, default: 0
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string :current_sign_in_ip
      t.string :last_sign_in_ip
      t.integer :failed_attempts, null: false, default: 0
      t.string :unlock_token
      t.datetime :locked_at
      t.boolean :administrador_sistema, null: false, default: false
      t.timestamps
    end
    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :unlock_token, unique: true

    create_table :espacos do |t|
      t.string :nome, null: false
      t.datetime :arquivado_em
      t.timestamps
    end
    add_check_constraint :espacos, "btrim(nome) <> ''", name: "espacos_nome_preenchido"

    create_table :membros_espaco do |t|
      t.references :espaco, null: false, foreign_key: { on_delete: :restrict }
      t.references :user, null: false, foreign_key: { on_delete: :restrict }
      t.string :papel, null: false
      t.timestamps
    end
    add_index :membros_espaco, %i[espaco_id user_id], unique: true
    add_check_constraint :membros_espaco, "papel IN ('administrador', 'editor', 'leitor')", name: "membros_espaco_papel_valido"

    create_table :moedas do |t|
      t.string :codigo, limit: 3, null: false
      t.string :nome, null: false
      t.integer :casas_decimais, null: false, default: 2
      t.datetime :arquivado_em
      t.timestamps
    end
    add_index :moedas, :codigo, unique: true
    add_check_constraint :moedas, "codigo ~ '^[A-Z]{3}$'", name: "moedas_codigo_valido"
    add_check_constraint :moedas, "casas_decimais BETWEEN 0 AND 10", name: "moedas_casas_decimais_validas"
    add_check_constraint :moedas, "btrim(nome) <> ''", name: "moedas_nome_preenchido"

    create_table :investidores do |t|
      t.references :espaco, null: false, foreign_key: { on_delete: :restrict }
      t.string :nome, null: false
      t.datetime :arquivado_em
      t.timestamps
    end
    add_index :investidores, "espaco_id, lower(nome)", unique: true, name: "idx_investidores_espaco_nome"
    add_check_constraint :investidores, "btrim(nome) <> ''", name: "investidores_nome_preenchido"

    create_table :instituicoes do |t|
      t.string :nome, null: false
      t.datetime :arquivado_em
      t.timestamps
    end
    add_index :instituicoes, "lower(nome)", unique: true, name: "idx_instituicoes_nome"
    add_check_constraint :instituicoes, "btrim(nome) <> ''", name: "instituicoes_nome_preenchido"

    create_table :fontes_cotacao do |t|
      t.string :codigo, null: false
      t.string :nome, null: false
      t.datetime :arquivado_em
      t.timestamps
    end
    add_index :fontes_cotacao, :codigo, unique: true
    add_check_constraint :fontes_cotacao, "codigo = upper(codigo) AND btrim(codigo) <> ''", name: "fontes_codigo_valido"
    add_check_constraint :fontes_cotacao, "btrim(nome) <> ''", name: "fontes_nome_preenchido"

    create_table :carteiras do |t|
      t.references :investidor, null: false, foreign_key: { on_delete: :restrict }
      t.string :nome, null: false
      t.references :moeda_base, null: false, foreign_key: { to_table: :moedas, on_delete: :restrict }
      t.datetime :arquivado_em
      t.timestamps
    end
    add_index :carteiras, "investidor_id, lower(nome)", unique: true, name: "idx_carteiras_investidor_nome"
    add_check_constraint :carteiras, "btrim(nome) <> ''", name: "carteiras_nome_preenchido"

    create_table :contas_investimento do |t|
      t.references :carteira, null: false, foreign_key: { on_delete: :restrict }
      t.references :instituicao, null: false, foreign_key: { on_delete: :restrict }
      t.string :nome, null: false
      t.string :identificador_externo
      t.datetime :arquivado_em
      t.timestamps
    end
    add_index :contas_investimento, "carteira_id, lower(nome)", unique: true, name: "idx_contas_investimento_carteira_nome"
    add_index :contas_investimento, :identificador_externo
    add_check_constraint :contas_investimento, "btrim(nome) <> ''", name: "contas_investimento_nome_preenchido"

    create_table :contas_caixa do |t|
      t.references :conta_investimento, null: false, foreign_key: { to_table: :contas_investimento, on_delete: :restrict }
      t.references :moeda, null: false, foreign_key: { on_delete: :restrict }
      t.datetime :arquivado_em
      t.timestamps
    end
    add_index :contas_caixa, %i[conta_investimento_id moeda_id], unique: true

    create_table :ativos do |t|
      t.string :codigo, null: false
      t.string :mercado, null: false
      t.string :descricao
      t.string :tipo, null: false
      t.references :moeda_negociacao, null: false, foreign_key: { to_table: :moedas, on_delete: :restrict }
      t.string :simbolo_yahoo
      t.string :cnpj
      t.datetime :arquivado_em
      t.timestamps
    end
    add_index :ativos, %i[codigo mercado], unique: true
    add_index :ativos, :simbolo_yahoo
    add_index :ativos, :cnpj
    add_check_constraint :ativos, "codigo = upper(codigo) AND btrim(codigo) <> ''", name: "ativos_codigo_valido"
    add_check_constraint :ativos, "mercado = upper(mercado) AND btrim(mercado) <> ''", name: "ativos_mercado_valido"
    add_check_constraint :ativos, "tipo IN ('acao', 'fii', 'fundo', 'etf', 'renda_fixa', 'criptoativo', 'outro')", name: "ativos_tipo_valido"
    add_check_constraint :ativos, "cnpj IS NULL OR cnpj ~ '^[0-9]{14}$'", name: "ativos_cnpj_valido"

    create_table :transacoes_financeiras do |t|
      t.references :investidor, null: false, foreign_key: { on_delete: :restrict }
      t.string :tipo, null: false
      t.string :origem, null: false
      t.date :data_competencia, null: false
      t.integer :ordem_na_data
      t.string :estado, null: false, default: "rascunho"
      t.references :criado_por, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.references :confirmado_por, foreign_key: { to_table: :users, on_delete: :restrict }
      t.text :observacao
      t.datetime :confirmada_em
      t.string :chave_idempotencia
      t.references :transacao_revertida, foreign_key: { to_table: :transacoes_financeiras, on_delete: :restrict }
      t.timestamps
    end
    add_index :transacoes_financeiras, %i[investidor_id chave_idempotencia], unique: true,
      where: "chave_idempotencia IS NOT NULL", name: "idx_transacoes_idempotencia"
    add_index :transacoes_financeiras, :transacao_revertida_id, unique: true,
      where: "transacao_revertida_id IS NOT NULL", name: "idx_transacoes_reversao_unica"
    add_index :transacoes_financeiras, %i[investidor_id data_competencia ordem_na_data id], name: "idx_transacoes_replay"
    add_check_constraint :transacoes_financeiras, "tipo IN ('nota_negociacao', 'provento', 'movimentacao_caixa', 'reversao')", name: "transacoes_tipo_valido"
    add_check_constraint :transacoes_financeiras, "origem IN ('manual', 'sistema')", name: "transacoes_origem_valida"
    add_check_constraint :transacoes_financeiras, "estado IN ('rascunho', 'confirmada')", name: "transacoes_estado_valido"
    add_check_constraint :transacoes_financeiras, "ordem_na_data IS NULL OR ordem_na_data > 0", name: "transacoes_ordem_positiva"
    add_check_constraint :transacoes_financeiras,
      "(estado = 'rascunho' AND confirmado_por_id IS NULL AND confirmada_em IS NULL) OR (estado = 'confirmada' AND confirmado_por_id IS NOT NULL AND confirmada_em IS NOT NULL AND ordem_na_data IS NOT NULL)",
      name: "transacoes_estado_estrutural"
    add_check_constraint :transacoes_financeiras,
      "(tipo = 'reversao' AND transacao_revertida_id IS NOT NULL AND origem = 'sistema' AND estado = 'confirmada') OR (tipo <> 'reversao' AND transacao_revertida_id IS NULL)",
      name: "transacoes_reversao_estrutural"

    create_table :notas_negociacao do |t|
      t.references :transacao_financeira, null: false, foreign_key: { to_table: :transacoes_financeiras, on_delete: :restrict }, index: { unique: true }
      t.references :conta_caixa, null: false, foreign_key: { to_table: :contas_caixa, on_delete: :restrict }
      t.date :data_negociacao, null: false
      t.date :data_liquidacao, null: false
      t.decimal :custo_operacional_total, precision: 30, scale: 12, null: false, default: 0
      t.decimal :taxa_conversao_base, precision: 24, scale: 12, null: false, default: 1
      t.timestamps
    end
    add_check_constraint :notas_negociacao, "data_negociacao <= data_liquidacao", name: "notas_datas_validas"
    add_check_constraint :notas_negociacao, "custo_operacional_total >= 0 AND taxa_conversao_base > 0", name: "notas_valores_validos"

    create_table :negociacoes do |t|
      t.references :nota_negociacao, null: false, foreign_key: { to_table: :notas_negociacao, on_delete: :restrict }
      t.integer :ordem, null: false
      t.references :ativo, null: false, foreign_key: { on_delete: :restrict }
      t.string :natureza, null: false
      t.decimal :quantidade, precision: 30, scale: 10, null: false
      t.decimal :preco_unitario, precision: 30, scale: 12, null: false
      t.decimal :custo_alocado, precision: 30, scale: 12, null: false
      t.timestamps
    end
    add_index :negociacoes, %i[nota_negociacao_id ordem], unique: true
    add_check_constraint :negociacoes, "ordem > 0", name: "negociacoes_ordem_positiva"
    add_check_constraint :negociacoes, "natureza IN ('compra', 'venda')", name: "negociacoes_natureza_valida"
    add_check_constraint :negociacoes, "quantidade > 0 AND preco_unitario > 0 AND custo_alocado >= 0", name: "negociacoes_valores_validos"

    create_table :proventos do |t|
      t.references :transacao_financeira, null: false, foreign_key: { to_table: :transacoes_financeiras, on_delete: :restrict }, index: { unique: true }
      t.references :conta_caixa, null: false, foreign_key: { to_table: :contas_caixa, on_delete: :restrict }
      t.references :ativo, null: false, foreign_key: { on_delete: :restrict }
      t.string :tipo, null: false
      t.date :data_base, null: false
      t.date :data_pagamento, null: false
      t.decimal :quantidade_referencia, precision: 30, scale: 10, null: false
      t.decimal :valor_bruto, precision: 30, scale: 12, null: false
      t.decimal :retencoes, precision: 30, scale: 12, null: false, default: 0
      t.decimal :valor_liquido, precision: 30, scale: 12, null: false
      t.decimal :taxa_conversao_base, precision: 24, scale: 12, null: false, default: 1
      t.timestamps
    end
    add_check_constraint :proventos, "tipo IN ('dividendo', 'jcp', 'rendimento', 'juros', 'outro')", name: "proventos_tipo_valido"
    add_check_constraint :proventos,
      "quantidade_referencia >= 0 AND valor_bruto >= 0 AND retencoes >= 0 AND valor_liquido >= 0 AND valor_liquido = valor_bruto - retencoes AND taxa_conversao_base > 0",
      name: "proventos_valores_validos"

    create_table :movimentacoes_caixa do |t|
      t.references :transacao_financeira, null: false, foreign_key: { to_table: :transacoes_financeiras, on_delete: :restrict }, index: { unique: true }
      t.string :tipo, null: false
      t.references :conta_caixa_origem, foreign_key: { to_table: :contas_caixa, on_delete: :restrict }
      t.references :conta_caixa_destino, foreign_key: { to_table: :contas_caixa, on_delete: :restrict }
      t.decimal :valor_origem, precision: 30, scale: 12
      t.decimal :valor_destino, precision: 30, scale: 12
      t.date :data_efetiva, null: false
      t.timestamps
    end
    add_check_constraint :movimentacoes_caixa, "tipo IN ('aporte', 'resgate', 'transferencia', 'cambio')", name: "movimentacoes_tipo_valido"
    add_check_constraint :movimentacoes_caixa, "valor_origem IS NULL OR valor_origem > 0", name: "movimentacoes_valor_origem_positivo"
    add_check_constraint :movimentacoes_caixa, "valor_destino IS NULL OR valor_destino > 0", name: "movimentacoes_valor_destino_positivo"
    add_check_constraint :movimentacoes_caixa,
      "(tipo = 'aporte' AND conta_caixa_origem_id IS NULL AND valor_origem IS NULL AND conta_caixa_destino_id IS NOT NULL AND valor_destino IS NOT NULL) OR (tipo = 'resgate' AND conta_caixa_origem_id IS NOT NULL AND valor_origem IS NOT NULL AND conta_caixa_destino_id IS NULL AND valor_destino IS NULL) OR (tipo IN ('transferencia', 'cambio') AND conta_caixa_origem_id IS NOT NULL AND valor_origem IS NOT NULL AND conta_caixa_destino_id IS NOT NULL AND valor_destino IS NOT NULL AND conta_caixa_origem_id <> conta_caixa_destino_id)",
      name: "movimentacoes_pernas_validas"
    add_check_constraint :movimentacoes_caixa, "tipo <> 'transferencia' OR valor_origem = valor_destino", name: "movimentacoes_transferencia_valores_iguais"

    create_table :lancamentos_caixa do |t|
      t.references :transacao_financeira, null: false, foreign_key: { to_table: :transacoes_financeiras, on_delete: :restrict }
      t.integer :ordem, null: false
      t.references :conta_caixa, null: false, foreign_key: { to_table: :contas_caixa, on_delete: :restrict }
      t.date :data_efetiva, null: false
      t.string :natureza, null: false
      t.decimal :valor, precision: 30, scale: 12, null: false
      t.references :lancamento_original, foreign_key: { to_table: :lancamentos_caixa, on_delete: :restrict }
      t.timestamps
    end
    add_index :lancamentos_caixa, %i[transacao_financeira_id ordem], unique: true, name: "idx_lancamentos_transacao_ordem"
    add_index :lancamentos_caixa, :lancamento_original_id, unique: true, where: "lancamento_original_id IS NOT NULL", name: "idx_lancamentos_reversao_unica"
    add_index :lancamentos_caixa, %i[conta_caixa_id data_efetiva transacao_financeira_id], name: "idx_lancamentos_saldo"
    add_check_constraint :lancamentos_caixa, "ordem > 0 AND valor <> 0", name: "lancamentos_valores_validos"
    add_check_constraint :lancamentos_caixa,
      "natureza IN ('liquidacao_nota', 'provento', 'aporte', 'resgate', 'transferencia_saida', 'transferencia_entrada', 'cambio_saida', 'cambio_entrada')",
      name: "lancamentos_natureza_valida"

    create_table :posicoes_atuais do |t|
      t.references :conta_investimento, null: false, foreign_key: { to_table: :contas_investimento, on_delete: :restrict }
      t.references :ativo, null: false, foreign_key: { on_delete: :restrict }
      t.decimal :quantidade, precision: 30, scale: 10, null: false
      t.decimal :custo_total_local, precision: 30, scale: 12, null: false
      t.decimal :custo_total_base, precision: 30, scale: 12, null: false
      t.references :ultima_transacao, null: false, foreign_key: { to_table: :transacoes_financeiras, on_delete: :restrict }
      t.timestamps
    end
    add_index :posicoes_atuais, %i[conta_investimento_id ativo_id], unique: true, name: "idx_posicoes_atuais_unica"
    add_check_constraint :posicoes_atuais, "quantidade > 0 AND custo_total_local >= 0 AND custo_total_base >= 0", name: "posicoes_valores_validos"

    create_table :cotacoes_ativos do |t|
      t.references :ativo, null: false, foreign_key: { on_delete: :restrict }
      t.date :data, null: false
      t.decimal :preco, precision: 30, scale: 12, null: false
      t.references :fonte_cotacao, null: false, foreign_key: { to_table: :fontes_cotacao, on_delete: :restrict }
      t.boolean :manual, null: false, default: false
      t.references :autor, foreign_key: { to_table: :users, on_delete: :restrict }
      t.timestamps
    end
    add_index :cotacoes_ativos, %i[ativo_id data], unique: true
    add_check_constraint :cotacoes_ativos, "preco > 0", name: "cotacoes_ativos_preco_positivo"
    add_check_constraint :cotacoes_ativos, "(manual AND autor_id IS NOT NULL) OR (NOT manual AND autor_id IS NULL)", name: "cotacoes_ativos_autoria_valida"

    create_table :cotacoes_cambio do |t|
      t.references :moeda_origem, null: false, foreign_key: { to_table: :moedas, on_delete: :restrict }
      t.references :moeda_destino, null: false, foreign_key: { to_table: :moedas, on_delete: :restrict }
      t.date :data, null: false
      t.decimal :taxa, precision: 24, scale: 12, null: false
      t.references :fonte_cotacao, null: false, foreign_key: { to_table: :fontes_cotacao, on_delete: :restrict }
      t.references :autor, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.timestamps
    end
    add_index :cotacoes_cambio, %i[moeda_origem_id moeda_destino_id data], unique: true, name: "idx_cotacoes_cambio_par_data"
    add_check_constraint :cotacoes_cambio, "moeda_origem_id <> moeda_destino_id AND taxa > 0", name: "cotacoes_cambio_valida"
  end
end
