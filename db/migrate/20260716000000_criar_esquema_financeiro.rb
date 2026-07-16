class CriarEsquemaFinanceiro < ActiveRecord::Migration[8.1]
  def change
    criar_usuarios
    criar_cadastros
    criar_eventos
    criar_livro_caixa_e_posicoes
    criar_importacoes
    criar_cotacoes
    criar_referencias_e_resumos
  end

  private

  def criar_usuarios
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
      t.integer :role, null: false, default: 0
      t.timestamps
    end
    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :unlock_token, unique: true
  end

  def criar_cadastros
    create_table :moedas do |t|
      t.string :codigo, null: false
      t.string :nome, null: false
      t.string :tipo, null: false
      t.integer :casas_decimais, null: false
      t.datetime :arquivado_em
      t.timestamps
    end
    add_index :moedas, :codigo, unique: true
    add_check_constraint :moedas, "codigo = upper(codigo)", name: "moedas_codigo_maiusculo"
    add_check_constraint :moedas, "tipo IN ('fiduciaria', 'criptoativo')", name: "moedas_tipo_valido"
    add_check_constraint :moedas, "casas_decimais BETWEEN 0 AND 18", name: "moedas_casas_decimais_validas"

    create_table :investidores do |t|
      t.references :user, null: false, foreign_key: { on_delete: :restrict }, index: { unique: true }
      t.string :nome, null: false
      t.references :moeda_fiscal, null: false, foreign_key: { to_table: :moedas, on_delete: :restrict }
      t.timestamps
    end

    create_table :carteiras do |t|
      t.references :investidor, null: false, foreign_key: { on_delete: :restrict }
      t.string :nome, null: false
      t.references :moeda_base, null: false, foreign_key: { to_table: :moedas, on_delete: :restrict }
      t.datetime :arquivado_em
      t.timestamps
    end
    add_index :carteiras, %i[investidor_id nome], unique: true

    create_table :corretoras do |t|
      t.string :nome, null: false
      t.string :pais, null: false
      t.datetime :arquivado_em
      t.timestamps
    end
    add_index :corretoras, %i[nome pais], unique: true

    create_table :contas_investimento do |t|
      t.references :carteira, null: false, foreign_key: { on_delete: :restrict }
      t.references :corretora, null: false, foreign_key: { on_delete: :restrict }
      t.string :nome, null: false
      t.string :identificador_externo
      t.datetime :arquivado_em
      t.timestamps
    end
    add_index :contas_investimento, %i[carteira_id nome], unique: true
    add_index :contas_investimento, %i[corretora_id identificador_externo], unique: true,
      where: "identificador_externo IS NOT NULL AND identificador_externo <> ''", name: "idx_contas_investimento_identificador"

    create_table :contas_caixa do |t|
      t.references :conta_investimento, null: false, foreign_key: { to_table: :contas_investimento, on_delete: :restrict }
      t.references :moeda, null: false, foreign_key: { on_delete: :restrict }
      t.timestamps
    end
    add_index :contas_caixa, %i[conta_investimento_id moeda_id], unique: true

    create_table :ativos do |t|
      t.string :codigo, null: false
      t.string :mercado, null: false
      t.string :descricao
      t.string :tipo, null: false
      t.references :moeda_negociacao, null: false, foreign_key: { to_table: :moedas, on_delete: :restrict }
      t.references :moeda_exposicao, null: false, foreign_key: { to_table: :moedas, on_delete: :restrict }
      t.string :cnpj
      t.datetime :arquivado_em
      t.timestamps
    end
    add_index :ativos, %i[codigo mercado], unique: true
    add_index :ativos, :cnpj
    add_index :ativos, :cnpj, unique: true, where: "cnpj IS NOT NULL AND tipo IN ('fundo', 'fii')",
      name: "idx_ativos_cnpj_unico_quando_aplicavel"
    add_check_constraint :ativos, "codigo = upper(codigo)", name: "ativos_codigo_maiusculo"
    add_check_constraint :ativos,
      "tipo IN ('acao', 'fii', 'fundo', 'criptomoeda', 'tesouro', 'etf', 'debenture', 'cra', 'cdb')",
      name: "ativos_tipo_valido"
  end

  def criar_eventos
    create_table :eventos_financeiros do |t|
      t.references :carteira, null: false, foreign_key: { on_delete: :restrict }
      t.string :tipo, null: false
      t.string :origem, null: false
      t.date :data_competencia, null: false
      t.bigint :sequencia_na_data
      t.string :estado, null: false, default: "rascunho"
      t.references :usuario_responsavel, null: false, foreign_key: { to_table: :users, on_delete: :restrict }
      t.string :chave_idempotencia
      t.references :evento_revertido, foreign_key: { to_table: :eventos_financeiros, on_delete: :restrict }
      t.text :observacao
      t.timestamps
    end
    add_index :eventos_financeiros, %i[carteira_id data_competencia sequencia_na_data id],
      name: "idx_eventos_ordem_replay"
    add_index :eventos_financeiros, %i[carteira_id chave_idempotencia], unique: true,
      where: "chave_idempotencia IS NOT NULL AND chave_idempotencia <> ''", name: "idx_eventos_idempotencia"
    add_index :eventos_financeiros, :evento_revertido_id, unique: true,
      where: "evento_revertido_id IS NOT NULL", name: "idx_eventos_reversao_unica"
    add_index :eventos_financeiros, %i[carteira_id data_competencia sequencia_na_data], unique: true,
      where: "sequencia_na_data IS NOT NULL", name: "idx_eventos_sequencia_unica"
    add_check_constraint :eventos_financeiros, "origem IN ('manual', 'importacao', 'sistema')", name: "eventos_origem_valida"
    add_check_constraint :eventos_financeiros, "estado IN ('rascunho', 'confirmado')", name: "eventos_estado_valido"
    add_check_constraint :eventos_financeiros,
      "estado <> 'confirmado' OR (sequencia_na_data IS NOT NULL AND sequencia_na_data > 0)",
      name: "eventos_confirmados_com_sequencia"
    add_check_constraint :eventos_financeiros,
      "tipo IN ('operacao', 'provento', 'movimentacao_caixa', 'transferencia_caixa', 'transferencia_custodia', 'evento_corporativo', 'reversao')",
      name: "eventos_tipo_valido"

    create_table :operacoes do |t|
      t.references :evento_financeiro, null: false, foreign_key: { to_table: :eventos_financeiros, on_delete: :restrict }, index: { unique: true }
      t.references :conta_investimento, null: false, foreign_key: { to_table: :contas_investimento, on_delete: :restrict }
      t.references :ativo, null: false, foreign_key: { on_delete: :restrict }
      t.string :natureza, null: false
      t.decimal :quantidade, precision: 30, scale: 10, null: false
      t.decimal :preco_unitario, precision: 30, scale: 12, null: false
      t.references :moeda, null: false, foreign_key: { on_delete: :restrict }
      t.date :data_negociacao, null: false
      t.date :data_liquidacao, null: false
      %i[taxa emolumentos corretagem iss_iof irrf outros].each do |campo|
        t.decimal campo, precision: 30, scale: 12, null: false, default: 0
      end
      t.decimal :taxa_conversao_base, precision: 24, scale: 12, null: false, default: 1
      t.decimal :taxa_conversao_fiscal, precision: 24, scale: 12, null: false, default: 1
      t.timestamps
    end
    add_index :operacoes, %i[conta_investimento_id ativo_id]
    add_check_constraint :operacoes, "natureza IN ('compra', 'venda')", name: "operacoes_natureza_valida"
    add_check_constraint :operacoes, "quantidade > 0 AND preco_unitario > 0", name: "operacoes_valores_positivos"
    add_check_constraint :operacoes,
      "taxa >= 0 AND emolumentos >= 0 AND corretagem >= 0 AND iss_iof >= 0 AND irrf >= 0 AND outros >= 0",
      name: "operacoes_custos_nao_negativos"
    add_check_constraint :operacoes, "taxa_conversao_base > 0 AND taxa_conversao_fiscal > 0", name: "operacoes_cambio_positivo"

    create_table :proventos do |t|
      t.references :evento_financeiro, null: false, foreign_key: { to_table: :eventos_financeiros, on_delete: :restrict }, index: { unique: true }
      t.references :conta_investimento, null: false, foreign_key: { to_table: :contas_investimento, on_delete: :restrict }
      t.references :ativo, null: false, foreign_key: { on_delete: :restrict }
      t.string :tipo, null: false
      t.decimal :quantidade_referencia, precision: 30, scale: 10, null: false
      t.decimal :valor_bruto, precision: 30, scale: 12, null: false
      t.decimal :tributos, precision: 30, scale: 12, null: false, default: 0
      t.decimal :valor_liquido, precision: 30, scale: 12, null: false
      t.references :moeda, null: false, foreign_key: { on_delete: :restrict }
      t.date :data_base, null: false
      t.date :data_pagamento, null: false
      t.decimal :taxa_conversao_base, precision: 24, scale: 12, null: false, default: 1
      t.decimal :taxa_conversao_fiscal, precision: 24, scale: 12, null: false, default: 1
      t.timestamps
    end
    add_check_constraint :proventos, "tipo IN ('dividendo', 'jcp', 'rendimento')", name: "proventos_tipo_valido"
    add_check_constraint :proventos,
      "quantidade_referencia >= 0 AND valor_bruto >= 0 AND tributos >= 0 AND valor_liquido >= 0 AND valor_liquido = valor_bruto - tributos",
      name: "proventos_valores_coerentes"
    add_check_constraint :proventos, "taxa_conversao_base > 0 AND taxa_conversao_fiscal > 0",
      name: "proventos_cambio_positivo"

    create_table :movimentacoes_caixa do |t|
      t.references :evento_financeiro, null: false, foreign_key: { to_table: :eventos_financeiros, on_delete: :restrict }, index: { unique: true }
      t.references :conta_caixa, null: false, foreign_key: { to_table: :contas_caixa, on_delete: :restrict }
      t.string :natureza, null: false
      t.string :direcao, null: false
      t.decimal :valor, precision: 30, scale: 12, null: false
      t.date :data_efetiva, null: false
      t.timestamps
    end
    add_check_constraint :movimentacoes_caixa, "natureza IN ('aporte', 'resgate', 'ajuste')", name: "movimentacoes_natureza_valida"
    add_check_constraint :movimentacoes_caixa, "direcao IN ('entrada', 'saida')", name: "movimentacoes_direcao_valida"
    add_check_constraint :movimentacoes_caixa, "valor > 0", name: "movimentacoes_valor_positivo"
    add_check_constraint :movimentacoes_caixa,
      "(natureza = 'aporte' AND direcao = 'entrada') OR (natureza = 'resgate' AND direcao = 'saida') OR natureza = 'ajuste'",
      name: "movimentacoes_natureza_direcao_coerentes"

    create_table :transferencias_caixa do |t|
      t.references :evento_financeiro, null: false, foreign_key: { to_table: :eventos_financeiros, on_delete: :restrict }, index: { unique: true }
      t.references :conta_caixa_origem, null: false, foreign_key: { to_table: :contas_caixa, on_delete: :restrict }
      t.references :conta_caixa_destino, null: false, foreign_key: { to_table: :contas_caixa, on_delete: :restrict }
      t.decimal :valor, precision: 30, scale: 12, null: false
      t.date :data_efetiva, null: false
      t.timestamps
    end
    add_check_constraint :transferencias_caixa, "valor > 0", name: "transferencias_caixa_valor_positivo"
    add_check_constraint :transferencias_caixa, "conta_caixa_origem_id <> conta_caixa_destino_id", name: "transferencias_caixa_contas_distintas"

    create_table :transferencias_custodia do |t|
      t.references :evento_financeiro, null: false, foreign_key: { to_table: :eventos_financeiros, on_delete: :restrict }, index: { unique: true }
      t.references :conta_origem, null: false, foreign_key: { to_table: :contas_investimento, on_delete: :restrict }
      t.references :conta_destino, null: false, foreign_key: { to_table: :contas_investimento, on_delete: :restrict }
      t.references :ativo, null: false, foreign_key: { on_delete: :restrict }
      t.decimal :quantidade, precision: 30, scale: 10, null: false
      t.timestamps
    end
    add_check_constraint :transferencias_custodia, "quantidade > 0", name: "transferencias_custodia_quantidade_positiva"
    add_check_constraint :transferencias_custodia, "conta_origem_id <> conta_destino_id", name: "transferencias_custodia_contas_distintas"

    create_table :eventos_corporativos do |t|
      t.references :evento_financeiro, null: false, foreign_key: { to_table: :eventos_financeiros, on_delete: :restrict }, index: { unique: true }
      t.string :tipo, null: false
      t.references :conta_investimento, null: false, foreign_key: { to_table: :contas_investimento, on_delete: :restrict }
      t.references :ativo_origem, null: false, foreign_key: { to_table: :ativos, on_delete: :restrict }
      t.references :ativo_destino, foreign_key: { to_table: :ativos, on_delete: :restrict }
      t.decimal :fator, precision: 30, scale: 12
      t.decimal :quantidade_final, precision: 30, scale: 10
      t.decimal :valor_fracao, precision: 30, scale: 12
      t.references :moeda, foreign_key: { on_delete: :restrict }
      t.decimal :taxa_conversao_base, precision: 24, scale: 12, null: false, default: 1
      t.decimal :percentual_custo_fracao, precision: 9, scale: 6
      t.string :regra_alocacao_custo, null: false
      t.timestamps
    end
    add_check_constraint :eventos_corporativos, "tipo IN ('desdobramento', 'grupamento', 'incorporacao')", name: "eventos_corporativos_tipo_valido"
    add_check_constraint :eventos_corporativos, "regra_alocacao_custo IN ('preservar', 'realizar_fracao')", name: "eventos_corporativos_regra_valida"
    add_check_constraint :eventos_corporativos, "fator IS NULL OR fator > 0", name: "eventos_corporativos_fator_positivo"
    add_check_constraint :eventos_corporativos, "quantidade_final IS NULL OR quantidade_final >= 0", name: "eventos_corporativos_quantidade_valida"
    add_check_constraint :eventos_corporativos, "valor_fracao IS NULL OR valor_fracao >= 0", name: "eventos_corporativos_fracao_valida"
    add_check_constraint :eventos_corporativos, "taxa_conversao_base > 0", name: "eventos_corporativos_cambio_positivo"
    add_check_constraint :eventos_corporativos,
      "ativo_destino_id IS NULL OR ativo_origem_id <> ativo_destino_id",
      name: "eventos_corporativos_ativos_distintos"
    add_check_constraint :eventos_corporativos,
      "(tipo IN ('desdobramento', 'grupamento') AND (fator IS NOT NULL OR quantidade_final IS NOT NULL)) OR (tipo = 'incorporacao' AND ativo_destino_id IS NOT NULL AND (fator IS NOT NULL OR quantidade_final IS NOT NULL))",
      name: "eventos_corporativos_parametros_suficientes"
    add_check_constraint :eventos_corporativos,
      "(valor_fracao IS NULL OR valor_fracao = 0) OR moeda_id IS NOT NULL",
      name: "eventos_corporativos_fracao_com_moeda"
    add_check_constraint :eventos_corporativos,
      "regra_alocacao_custo <> 'realizar_fracao' OR (valor_fracao > 0 AND percentual_custo_fracao > 0 AND percentual_custo_fracao <= 100)",
      name: "eventos_corporativos_alocacao_fracao_explicita"
    add_check_constraint :eventos_corporativos,
      "valor_fracao IS NULL OR valor_fracao = 0 OR regra_alocacao_custo = 'realizar_fracao'",
      name: "eventos_corporativos_fracao_realizada"
  end

  def criar_livro_caixa_e_posicoes
    create_table :lancamentos_caixa do |t|
      t.references :evento_financeiro, null: false, foreign_key: { to_table: :eventos_financeiros, on_delete: :restrict }
      t.references :conta_caixa, null: false, foreign_key: { to_table: :contas_caixa, on_delete: :restrict }
      t.date :data_efetiva, null: false
      t.string :natureza, null: false
      t.decimal :valor, precision: 30, scale: 12, null: false
      t.timestamps
    end
    add_index :lancamentos_caixa, %i[conta_caixa_id data_efetiva evento_financeiro_id], name: "idx_lancamentos_consulta_saldo"
    add_index :lancamentos_caixa, %i[evento_financeiro_id conta_caixa_id natureza], unique: true, name: "idx_lancamentos_idempotentes"
    add_check_constraint :lancamentos_caixa, "valor <> 0", name: "lancamentos_valor_nao_zero"

    create_table :posicoes_atuais do |t|
      t.references :conta_investimento, null: false, foreign_key: { to_table: :contas_investimento, on_delete: :restrict }
      t.references :ativo, null: false, foreign_key: { on_delete: :restrict }
      t.decimal :quantidade, precision: 30, scale: 10, null: false, default: 0
      t.decimal :custo_total, precision: 30, scale: 12, null: false, default: 0
      t.decimal :custo_total_base, precision: 30, scale: 12, null: false, default: 0
      t.decimal :resultado_realizado, precision: 30, scale: 12, null: false, default: 0
      t.references :ultimo_evento_aplicado, foreign_key: { to_table: :eventos_financeiros, on_delete: :restrict }
      t.bigint :versao, null: false, default: 0
      t.timestamps
    end
    add_index :posicoes_atuais, %i[conta_investimento_id ativo_id], unique: true, name: "idx_posicoes_atuais_unica"
    add_check_constraint :posicoes_atuais,
      "(quantidade = 0 AND custo_total = 0 AND custo_total_base = 0) OR quantidade <> 0",
      name: "posicoes_zeradas_sem_custo"

    create_table :resultados_operacoes do |t|
      t.references :operacao, null: false, foreign_key: { on_delete: :restrict }
      t.decimal :quantidade_encerrada, precision: 30, scale: 10, null: false
      t.decimal :custo_alocado, precision: 30, scale: 12, null: false
      t.decimal :valor_alienacao, precision: 30, scale: 12, null: false
      t.decimal :custos_alocados, precision: 30, scale: 12, null: false
      t.decimal :resultado_realizado, precision: 30, scale: 12, null: false
      t.timestamps
    end
    add_check_constraint :resultados_operacoes, "quantidade_encerrada > 0 AND custos_alocados >= 0", name: "resultados_operacoes_valores_validos"
  end

  def criar_importacoes
    create_table :importacoes_extrato do |t|
      t.references :conta_caixa, null: false, foreign_key: { to_table: :contas_caixa, on_delete: :restrict }
      t.references :corretora, null: false, foreign_key: { on_delete: :restrict }
      t.string :nome_original, null: false
      t.string :checksum_sha256, null: false
      t.string :formato, null: false
      t.string :estado, null: false, default: "normalizada"
      t.integer :total_itens, null: false, default: 0
      t.integer :itens_processados, null: false, default: 0
      t.integer :itens_pendentes, null: false, default: 0
      t.text :erro_resumido
      t.timestamps
    end
    add_index :importacoes_extrato, %i[conta_caixa_id checksum_sha256], unique: true, name: "idx_importacoes_checksum"
    add_index :importacoes_extrato, %i[conta_caixa_id estado]
    add_check_constraint :importacoes_extrato, "estado IN ('normalizada', 'processando', 'concluida', 'falhou')", name: "importacoes_estado_valido"

    create_table :itens_extrato_importado do |t|
      t.references :importacao_extrato, null: false, foreign_key: { to_table: :importacoes_extrato, on_delete: :restrict }
      t.integer :ordem, null: false
      t.date :data_movimentacao, null: false
      t.date :data_liquidacao, null: false
      t.string :descricao, null: false
      t.decimal :valor, precision: 30, scale: 12, null: false
      t.references :moeda, null: false, foreign_key: { on_delete: :restrict }
      t.decimal :saldo_informado, precision: 30, scale: 12
      t.string :identificador_externo
      t.string :chave_deduplicacao, null: false
      t.jsonb :dados_normalizados, null: false, default: {}
      t.string :classificacao
      t.string :estado_conciliacao, null: false, default: "pendente"
      t.references :evento_financeiro, foreign_key: { to_table: :eventos_financeiros, on_delete: :restrict }
      t.references :lancamento_caixa, foreign_key: { to_table: :lancamentos_caixa, on_delete: :restrict }
      t.string :decisao
      t.references :usuario_responsavel, foreign_key: { to_table: :users, on_delete: :restrict }
      t.datetime :decidido_em
      t.timestamps
    end
    add_index :itens_extrato_importado, %i[importacao_extrato_id ordem], unique: true, name: "idx_itens_importacao_ordem"
    add_index :itens_extrato_importado, :identificador_externo
    add_index :itens_extrato_importado, :chave_deduplicacao
    add_check_constraint :itens_extrato_importado,
      "NOT (evento_financeiro_id IS NOT NULL AND lancamento_caixa_id IS NOT NULL)", name: "itens_conciliacao_exclusiva"
    add_check_constraint :itens_extrato_importado,
      "estado_conciliacao IN ('pendente', 'conciliado', 'evento_criado', 'ambiguo', 'ignorado')", name: "itens_estado_conciliacao_valido"
  end

  def criar_cotacoes
    create_table :fontes_cotacao do |t|
      t.string :nome, null: false
      t.integer :prioridade, null: false
      t.string :tipos_atendidos, array: true, null: false, default: []
      t.datetime :arquivado_em
      t.timestamps
    end
    add_index :fontes_cotacao, :nome, unique: true
    add_index :fontes_cotacao, :prioridade
    add_check_constraint :fontes_cotacao, "prioridade >= 0", name: "fontes_prioridade_valida"

    create_table :cotacoes_ativos do |t|
      t.references :ativo, null: false, foreign_key: { on_delete: :restrict }
      t.date :data, null: false
      t.decimal :preco, precision: 30, scale: 12, null: false
      t.references :moeda, null: false, foreign_key: { on_delete: :restrict }
      t.references :fonte_cotacao, null: false, foreign_key: { to_table: :fontes_cotacao, on_delete: :restrict }
      t.boolean :manual, null: false, default: false
      t.references :usuario_responsavel, foreign_key: { to_table: :users, on_delete: :restrict }
      t.timestamps
    end
    add_index :cotacoes_ativos, %i[ativo_id data], unique: true
    add_check_constraint :cotacoes_ativos, "preco > 0", name: "cotacoes_ativos_preco_positivo"

    create_table :cotacoes_cambio do |t|
      t.references :moeda_origem, null: false, foreign_key: { to_table: :moedas, on_delete: :restrict }
      t.references :moeda_destino, null: false, foreign_key: { to_table: :moedas, on_delete: :restrict }
      t.date :data, null: false
      t.decimal :taxa, precision: 24, scale: 12, null: false
      t.references :fonte_cotacao, null: false, foreign_key: { to_table: :fontes_cotacao, on_delete: :restrict }
      t.boolean :manual, null: false, default: false
      t.references :usuario_responsavel, foreign_key: { to_table: :users, on_delete: :restrict }
      t.timestamps
    end
    add_index :cotacoes_cambio, %i[moeda_origem_id moeda_destino_id data], unique: true, name: "idx_cotacoes_cambio_unica"
    add_check_constraint :cotacoes_cambio, "taxa > 0", name: "cotacoes_cambio_taxa_positiva"
    add_check_constraint :cotacoes_cambio, "moeda_origem_id <> moeda_destino_id", name: "cotacoes_cambio_moedas_distintas"
  end

  def criar_referencias_e_resumos
    create_table :referencias do |t|
      t.string :nome, null: false
      t.text :descricao
      t.timestamps
    end
    add_index :referencias, :nome, unique: true

    create_table :versoes_referencia do |t|
      t.references :referencia, null: false, foreign_key: { on_delete: :restrict }
      t.date :vigencia_inicial, null: false
      t.string :estado, null: false, default: "rascunho"
      t.timestamps
    end
    add_index :versoes_referencia, %i[referencia_id vigencia_inicial], unique: true, name: "idx_versoes_referencia_vigencia"
    add_check_constraint :versoes_referencia, "estado IN ('rascunho', 'publicada', 'encerrada')", name: "versoes_referencia_estado_valido"

    create_table :alocacoes_referencia do |t|
      t.references :versao_referencia, null: false, foreign_key: { to_table: :versoes_referencia, on_delete: :restrict }
      t.references :ativo, null: false, foreign_key: { on_delete: :restrict }
      t.string :categoria, null: false
      t.decimal :percentual, precision: 9, scale: 6, null: false
      t.timestamps
    end
    add_index :alocacoes_referencia, %i[versao_referencia_id ativo_id], unique: true, name: "idx_alocacoes_referencia_unica"
    add_check_constraint :alocacoes_referencia, "percentual >= 0 AND percentual <= 100", name: "alocacoes_percentual_valido"

    create_table :resumos_diarios_carteira do |t|
      t.references :carteira, null: false, foreign_key: { on_delete: :restrict }
      t.date :data, null: false
      t.decimal :patrimonio_inicial, precision: 30, scale: 12
      t.decimal :patrimonio_final, precision: 30, scale: 12
      t.decimal :valor_ativos, precision: 30, scale: 12
      t.decimal :valor_caixa, precision: 30, scale: 12
      t.decimal :fluxo_externo_liquido, precision: 30, scale: 12, null: false, default: 0
      t.decimal :resultado_diario, precision: 30, scale: 12
      t.decimal :twr_diario, precision: 24, scale: 12
      t.date :data_cotacoes_usadas
      t.string :estado_completude, null: false
      t.timestamps
    end
    add_index :resumos_diarios_carteira, %i[carteira_id data], unique: true, name: "idx_resumos_diarios_unico"
    add_check_constraint :resumos_diarios_carteira, "estado_completude IN ('completo', 'incompleto', 'sem_patrimonio_inicial')", name: "resumos_estado_valido"
  end
end
