# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_16_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "alocacoes_referencia", force: :cascade do |t|
    t.bigint "ativo_id", null: false
    t.string "categoria", null: false
    t.datetime "created_at", null: false
    t.decimal "percentual", precision: 9, scale: 6, null: false
    t.datetime "updated_at", null: false
    t.bigint "versao_referencia_id", null: false
    t.index ["ativo_id"], name: "index_alocacoes_referencia_on_ativo_id"
    t.index ["versao_referencia_id", "ativo_id"], name: "idx_alocacoes_referencia_unica", unique: true
    t.index ["versao_referencia_id"], name: "index_alocacoes_referencia_on_versao_referencia_id"
    t.check_constraint "percentual >= 0::numeric AND percentual <= 100::numeric", name: "alocacoes_percentual_valido"
  end

  create_table "ativos", force: :cascade do |t|
    t.datetime "arquivado_em"
    t.string "cnpj"
    t.string "codigo", null: false
    t.datetime "created_at", null: false
    t.string "descricao"
    t.string "mercado", null: false
    t.bigint "moeda_exposicao_id", null: false
    t.bigint "moeda_negociacao_id", null: false
    t.string "tipo", null: false
    t.datetime "updated_at", null: false
    t.index ["cnpj"], name: "idx_ativos_cnpj_unico_quando_aplicavel", unique: true, where: "((cnpj IS NOT NULL) AND ((tipo)::text = ANY (ARRAY[('fundo'::character varying)::text, ('fii'::character varying)::text])))"
    t.index ["cnpj"], name: "index_ativos_on_cnpj"
    t.index ["codigo", "mercado"], name: "index_ativos_on_codigo_and_mercado", unique: true
    t.index ["moeda_exposicao_id"], name: "index_ativos_on_moeda_exposicao_id"
    t.index ["moeda_negociacao_id"], name: "index_ativos_on_moeda_negociacao_id"
    t.check_constraint "codigo::text = upper(codigo::text)", name: "ativos_codigo_maiusculo"
    t.check_constraint "tipo::text = ANY (ARRAY['acao'::character varying::text, 'fii'::character varying::text, 'fundo'::character varying::text, 'criptomoeda'::character varying::text, 'tesouro'::character varying::text, 'etf'::character varying::text, 'debenture'::character varying::text, 'cra'::character varying::text, 'cdb'::character varying::text])", name: "ativos_tipo_valido"
  end

  create_table "carteiras", force: :cascade do |t|
    t.datetime "arquivado_em"
    t.datetime "created_at", null: false
    t.bigint "investidor_id", null: false
    t.bigint "moeda_base_id", null: false
    t.string "nome", null: false
    t.datetime "updated_at", null: false
    t.index ["investidor_id", "nome"], name: "index_carteiras_on_investidor_id_and_nome", unique: true
    t.index ["investidor_id"], name: "index_carteiras_on_investidor_id"
    t.index ["moeda_base_id"], name: "index_carteiras_on_moeda_base_id"
  end

  create_table "contas_caixa", force: :cascade do |t|
    t.bigint "conta_investimento_id", null: false
    t.datetime "created_at", null: false
    t.bigint "moeda_id", null: false
    t.datetime "updated_at", null: false
    t.index ["conta_investimento_id", "moeda_id"], name: "index_contas_caixa_on_conta_investimento_id_and_moeda_id", unique: true
    t.index ["conta_investimento_id"], name: "index_contas_caixa_on_conta_investimento_id"
    t.index ["moeda_id"], name: "index_contas_caixa_on_moeda_id"
  end

  create_table "contas_investimento", force: :cascade do |t|
    t.datetime "arquivado_em"
    t.bigint "carteira_id", null: false
    t.bigint "corretora_id", null: false
    t.datetime "created_at", null: false
    t.string "identificador_externo"
    t.string "nome", null: false
    t.datetime "updated_at", null: false
    t.index ["carteira_id", "nome"], name: "index_contas_investimento_on_carteira_id_and_nome", unique: true
    t.index ["carteira_id"], name: "index_contas_investimento_on_carteira_id"
    t.index ["corretora_id", "identificador_externo"], name: "idx_contas_investimento_identificador", unique: true, where: "((identificador_externo IS NOT NULL) AND ((identificador_externo)::text <> ''::text))"
    t.index ["corretora_id"], name: "index_contas_investimento_on_corretora_id"
  end

  create_table "corretoras", force: :cascade do |t|
    t.datetime "arquivado_em"
    t.datetime "created_at", null: false
    t.string "nome", null: false
    t.string "pais", null: false
    t.datetime "updated_at", null: false
    t.index ["nome", "pais"], name: "index_corretoras_on_nome_and_pais", unique: true
  end

  create_table "cotacoes_ativos", force: :cascade do |t|
    t.bigint "ativo_id", null: false
    t.datetime "created_at", null: false
    t.date "data", null: false
    t.bigint "fonte_cotacao_id", null: false
    t.boolean "manual", default: false, null: false
    t.bigint "moeda_id", null: false
    t.decimal "preco", precision: 30, scale: 12, null: false
    t.datetime "updated_at", null: false
    t.bigint "usuario_responsavel_id"
    t.index ["ativo_id", "data"], name: "index_cotacoes_ativos_on_ativo_id_and_data", unique: true
    t.index ["ativo_id"], name: "index_cotacoes_ativos_on_ativo_id"
    t.index ["fonte_cotacao_id"], name: "index_cotacoes_ativos_on_fonte_cotacao_id"
    t.index ["moeda_id"], name: "index_cotacoes_ativos_on_moeda_id"
    t.index ["usuario_responsavel_id"], name: "index_cotacoes_ativos_on_usuario_responsavel_id"
    t.check_constraint "preco > 0::numeric", name: "cotacoes_ativos_preco_positivo"
  end

  create_table "cotacoes_cambio", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "data", null: false
    t.bigint "fonte_cotacao_id", null: false
    t.boolean "manual", default: false, null: false
    t.bigint "moeda_destino_id", null: false
    t.bigint "moeda_origem_id", null: false
    t.decimal "taxa", precision: 24, scale: 12, null: false
    t.datetime "updated_at", null: false
    t.bigint "usuario_responsavel_id"
    t.index ["fonte_cotacao_id"], name: "index_cotacoes_cambio_on_fonte_cotacao_id"
    t.index ["moeda_destino_id"], name: "index_cotacoes_cambio_on_moeda_destino_id"
    t.index ["moeda_origem_id", "moeda_destino_id", "data"], name: "idx_cotacoes_cambio_unica", unique: true
    t.index ["moeda_origem_id"], name: "index_cotacoes_cambio_on_moeda_origem_id"
    t.index ["usuario_responsavel_id"], name: "index_cotacoes_cambio_on_usuario_responsavel_id"
    t.check_constraint "moeda_origem_id <> moeda_destino_id", name: "cotacoes_cambio_moedas_distintas"
    t.check_constraint "taxa > 0::numeric", name: "cotacoes_cambio_taxa_positiva"
  end

  create_table "eventos_corporativos", force: :cascade do |t|
    t.bigint "ativo_destino_id"
    t.bigint "ativo_origem_id", null: false
    t.bigint "conta_investimento_id", null: false
    t.datetime "created_at", null: false
    t.bigint "evento_financeiro_id", null: false
    t.decimal "fator", precision: 30, scale: 12
    t.bigint "moeda_id"
    t.decimal "percentual_custo_fracao", precision: 9, scale: 6
    t.decimal "quantidade_final", precision: 30, scale: 10
    t.string "regra_alocacao_custo", null: false
    t.decimal "taxa_conversao_base", precision: 24, scale: 12, default: "1.0", null: false
    t.string "tipo", null: false
    t.datetime "updated_at", null: false
    t.decimal "valor_fracao", precision: 30, scale: 12
    t.index ["ativo_destino_id"], name: "index_eventos_corporativos_on_ativo_destino_id"
    t.index ["ativo_origem_id"], name: "index_eventos_corporativos_on_ativo_origem_id"
    t.index ["conta_investimento_id"], name: "index_eventos_corporativos_on_conta_investimento_id"
    t.index ["evento_financeiro_id"], name: "index_eventos_corporativos_on_evento_financeiro_id", unique: true
    t.index ["moeda_id"], name: "index_eventos_corporativos_on_moeda_id"
    t.check_constraint "(tipo::text = ANY (ARRAY['desdobramento'::character varying::text, 'grupamento'::character varying::text])) AND (fator IS NOT NULL OR quantidade_final IS NOT NULL) OR tipo::text = 'incorporacao'::text AND ativo_destino_id IS NOT NULL AND (fator IS NOT NULL OR quantidade_final IS NOT NULL)", name: "eventos_corporativos_parametros_suficientes"
    t.check_constraint "ativo_destino_id IS NULL OR ativo_origem_id <> ativo_destino_id", name: "eventos_corporativos_ativos_distintos"
    t.check_constraint "fator IS NULL OR fator > 0::numeric", name: "eventos_corporativos_fator_positivo"
    t.check_constraint "quantidade_final IS NULL OR quantidade_final >= 0::numeric", name: "eventos_corporativos_quantidade_valida"
    t.check_constraint "regra_alocacao_custo::text <> 'realizar_fracao'::text OR valor_fracao > 0::numeric AND percentual_custo_fracao > 0::numeric AND percentual_custo_fracao <= 100::numeric", name: "eventos_corporativos_alocacao_fracao_explicita"
    t.check_constraint "regra_alocacao_custo::text = ANY (ARRAY['preservar'::character varying::text, 'realizar_fracao'::character varying::text])", name: "eventos_corporativos_regra_valida"
    t.check_constraint "taxa_conversao_base > 0::numeric", name: "eventos_corporativos_cambio_positivo"
    t.check_constraint "tipo::text = ANY (ARRAY['desdobramento'::character varying::text, 'grupamento'::character varying::text, 'incorporacao'::character varying::text])", name: "eventos_corporativos_tipo_valido"
    t.check_constraint "valor_fracao IS NULL OR valor_fracao = 0::numeric OR moeda_id IS NOT NULL", name: "eventos_corporativos_fracao_com_moeda"
    t.check_constraint "valor_fracao IS NULL OR valor_fracao = 0::numeric OR regra_alocacao_custo::text = 'realizar_fracao'::text", name: "eventos_corporativos_fracao_realizada"
    t.check_constraint "valor_fracao IS NULL OR valor_fracao >= 0::numeric", name: "eventos_corporativos_fracao_valida"
  end

  create_table "eventos_financeiros", force: :cascade do |t|
    t.bigint "carteira_id", null: false
    t.string "chave_idempotencia"
    t.datetime "created_at", null: false
    t.date "data_competencia", null: false
    t.string "estado", default: "rascunho", null: false
    t.bigint "evento_revertido_id"
    t.text "observacao"
    t.string "origem", null: false
    t.bigint "sequencia_na_data"
    t.string "tipo", null: false
    t.datetime "updated_at", null: false
    t.bigint "usuario_responsavel_id", null: false
    t.index ["carteira_id", "chave_idempotencia"], name: "idx_eventos_idempotencia", unique: true, where: "((chave_idempotencia IS NOT NULL) AND ((chave_idempotencia)::text <> ''::text))"
    t.index ["carteira_id", "data_competencia", "sequencia_na_data", "id"], name: "idx_eventos_ordem_replay"
    t.index ["carteira_id", "data_competencia", "sequencia_na_data"], name: "idx_eventos_sequencia_unica", unique: true, where: "(sequencia_na_data IS NOT NULL)"
    t.index ["carteira_id"], name: "index_eventos_financeiros_on_carteira_id"
    t.index ["evento_revertido_id"], name: "idx_eventos_reversao_unica", unique: true, where: "(evento_revertido_id IS NOT NULL)"
    t.index ["evento_revertido_id"], name: "index_eventos_financeiros_on_evento_revertido_id"
    t.index ["usuario_responsavel_id"], name: "index_eventos_financeiros_on_usuario_responsavel_id"
    t.check_constraint "estado::text <> 'confirmado'::text OR sequencia_na_data IS NOT NULL AND sequencia_na_data > 0", name: "eventos_confirmados_com_sequencia"
    t.check_constraint "estado::text = ANY (ARRAY['rascunho'::character varying::text, 'confirmado'::character varying::text])", name: "eventos_estado_valido"
    t.check_constraint "origem::text = ANY (ARRAY['manual'::character varying::text, 'importacao'::character varying::text, 'sistema'::character varying::text])", name: "eventos_origem_valida"
    t.check_constraint "tipo::text = ANY (ARRAY['operacao'::character varying::text, 'provento'::character varying::text, 'movimentacao_caixa'::character varying::text, 'transferencia_caixa'::character varying::text, 'transferencia_custodia'::character varying::text, 'evento_corporativo'::character varying::text, 'reversao'::character varying::text])", name: "eventos_tipo_valido"
  end

  create_table "fontes_cotacao", force: :cascade do |t|
    t.datetime "arquivado_em"
    t.datetime "created_at", null: false
    t.string "nome", null: false
    t.integer "prioridade", null: false
    t.string "tipos_atendidos", default: [], null: false, array: true
    t.datetime "updated_at", null: false
    t.index ["nome"], name: "index_fontes_cotacao_on_nome", unique: true
    t.index ["prioridade"], name: "index_fontes_cotacao_on_prioridade"
    t.check_constraint "prioridade >= 0", name: "fontes_prioridade_valida"
  end

  create_table "importacoes_extrato", force: :cascade do |t|
    t.string "checksum_sha256", null: false
    t.bigint "conta_caixa_id", null: false
    t.bigint "corretora_id", null: false
    t.datetime "created_at", null: false
    t.text "erro_resumido"
    t.string "estado", default: "normalizada", null: false
    t.string "formato", null: false
    t.integer "itens_pendentes", default: 0, null: false
    t.integer "itens_processados", default: 0, null: false
    t.string "nome_original", null: false
    t.integer "total_itens", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["conta_caixa_id", "checksum_sha256"], name: "idx_importacoes_checksum", unique: true
    t.index ["conta_caixa_id", "estado"], name: "index_importacoes_extrato_on_conta_caixa_id_and_estado"
    t.index ["conta_caixa_id"], name: "index_importacoes_extrato_on_conta_caixa_id"
    t.index ["corretora_id"], name: "index_importacoes_extrato_on_corretora_id"
    t.check_constraint "estado::text = ANY (ARRAY['normalizada'::character varying::text, 'processando'::character varying::text, 'concluida'::character varying::text, 'falhou'::character varying::text])", name: "importacoes_estado_valido"
  end

  create_table "investidores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "moeda_fiscal_id", null: false
    t.string "nome", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["moeda_fiscal_id"], name: "index_investidores_on_moeda_fiscal_id"
    t.index ["user_id"], name: "index_investidores_on_user_id", unique: true
  end

  create_table "itens_extrato_importado", force: :cascade do |t|
    t.string "chave_deduplicacao", null: false
    t.string "classificacao"
    t.datetime "created_at", null: false
    t.jsonb "dados_normalizados", default: {}, null: false
    t.date "data_liquidacao", null: false
    t.date "data_movimentacao", null: false
    t.datetime "decidido_em"
    t.string "decisao"
    t.string "descricao", null: false
    t.string "estado_conciliacao", default: "pendente", null: false
    t.bigint "evento_financeiro_id"
    t.string "identificador_externo"
    t.bigint "importacao_extrato_id", null: false
    t.bigint "lancamento_caixa_id"
    t.bigint "moeda_id", null: false
    t.integer "ordem", null: false
    t.decimal "saldo_informado", precision: 30, scale: 12
    t.datetime "updated_at", null: false
    t.bigint "usuario_responsavel_id"
    t.decimal "valor", precision: 30, scale: 12, null: false
    t.index ["chave_deduplicacao"], name: "index_itens_extrato_importado_on_chave_deduplicacao"
    t.index ["evento_financeiro_id"], name: "index_itens_extrato_importado_on_evento_financeiro_id"
    t.index ["identificador_externo"], name: "index_itens_extrato_importado_on_identificador_externo"
    t.index ["importacao_extrato_id", "ordem"], name: "idx_itens_importacao_ordem", unique: true
    t.index ["importacao_extrato_id"], name: "index_itens_extrato_importado_on_importacao_extrato_id"
    t.index ["lancamento_caixa_id"], name: "index_itens_extrato_importado_on_lancamento_caixa_id"
    t.index ["moeda_id"], name: "index_itens_extrato_importado_on_moeda_id"
    t.index ["usuario_responsavel_id"], name: "index_itens_extrato_importado_on_usuario_responsavel_id"
    t.check_constraint "NOT (evento_financeiro_id IS NOT NULL AND lancamento_caixa_id IS NOT NULL)", name: "itens_conciliacao_exclusiva"
    t.check_constraint "estado_conciliacao::text = ANY (ARRAY['pendente'::character varying::text, 'conciliado'::character varying::text, 'evento_criado'::character varying::text, 'ambiguo'::character varying::text, 'ignorado'::character varying::text])", name: "itens_estado_conciliacao_valido"
  end

  create_table "lancamentos_caixa", force: :cascade do |t|
    t.bigint "conta_caixa_id", null: false
    t.datetime "created_at", null: false
    t.date "data_efetiva", null: false
    t.bigint "evento_financeiro_id", null: false
    t.string "natureza", null: false
    t.datetime "updated_at", null: false
    t.decimal "valor", precision: 30, scale: 12, null: false
    t.index ["conta_caixa_id", "data_efetiva", "evento_financeiro_id"], name: "idx_lancamentos_consulta_saldo"
    t.index ["conta_caixa_id"], name: "index_lancamentos_caixa_on_conta_caixa_id"
    t.index ["evento_financeiro_id", "conta_caixa_id", "natureza"], name: "idx_lancamentos_idempotentes", unique: true
    t.index ["evento_financeiro_id"], name: "index_lancamentos_caixa_on_evento_financeiro_id"
    t.check_constraint "valor <> 0::numeric", name: "lancamentos_valor_nao_zero"
  end

  create_table "moedas", force: :cascade do |t|
    t.datetime "arquivado_em"
    t.integer "casas_decimais", null: false
    t.string "codigo", null: false
    t.datetime "created_at", null: false
    t.string "nome", null: false
    t.string "tipo", null: false
    t.datetime "updated_at", null: false
    t.index ["codigo"], name: "index_moedas_on_codigo", unique: true
    t.check_constraint "casas_decimais >= 0 AND casas_decimais <= 18", name: "moedas_casas_decimais_validas"
    t.check_constraint "codigo::text = upper(codigo::text)", name: "moedas_codigo_maiusculo"
    t.check_constraint "tipo::text = ANY (ARRAY['fiduciaria'::character varying::text, 'criptoativo'::character varying::text])", name: "moedas_tipo_valido"
  end

  create_table "movimentacoes_caixa", force: :cascade do |t|
    t.bigint "conta_caixa_id", null: false
    t.datetime "created_at", null: false
    t.date "data_efetiva", null: false
    t.string "direcao", null: false
    t.bigint "evento_financeiro_id", null: false
    t.string "natureza", null: false
    t.datetime "updated_at", null: false
    t.decimal "valor", precision: 30, scale: 12, null: false
    t.index ["conta_caixa_id"], name: "index_movimentacoes_caixa_on_conta_caixa_id"
    t.index ["evento_financeiro_id"], name: "index_movimentacoes_caixa_on_evento_financeiro_id", unique: true
    t.check_constraint "direcao::text = ANY (ARRAY['entrada'::character varying::text, 'saida'::character varying::text])", name: "movimentacoes_direcao_valida"
    t.check_constraint "natureza::text = 'aporte'::text AND direcao::text = 'entrada'::text OR natureza::text = 'resgate'::text AND direcao::text = 'saida'::text OR natureza::text = 'ajuste'::text", name: "movimentacoes_natureza_direcao_coerentes"
    t.check_constraint "natureza::text = ANY (ARRAY['aporte'::character varying::text, 'resgate'::character varying::text, 'ajuste'::character varying::text])", name: "movimentacoes_natureza_valida"
    t.check_constraint "valor > 0::numeric", name: "movimentacoes_valor_positivo"
  end

  create_table "operacoes", force: :cascade do |t|
    t.bigint "ativo_id", null: false
    t.bigint "conta_investimento_id", null: false
    t.decimal "corretagem", precision: 30, scale: 12, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.date "data_liquidacao", null: false
    t.date "data_negociacao", null: false
    t.decimal "emolumentos", precision: 30, scale: 12, default: "0.0", null: false
    t.bigint "evento_financeiro_id", null: false
    t.decimal "irrf", precision: 30, scale: 12, default: "0.0", null: false
    t.decimal "iss_iof", precision: 30, scale: 12, default: "0.0", null: false
    t.bigint "moeda_id", null: false
    t.string "natureza", null: false
    t.decimal "outros", precision: 30, scale: 12, default: "0.0", null: false
    t.decimal "preco_unitario", precision: 30, scale: 12, null: false
    t.decimal "quantidade", precision: 30, scale: 10, null: false
    t.decimal "taxa", precision: 30, scale: 12, default: "0.0", null: false
    t.decimal "taxa_conversao_base", precision: 24, scale: 12, default: "1.0", null: false
    t.decimal "taxa_conversao_fiscal", precision: 24, scale: 12, default: "1.0", null: false
    t.datetime "updated_at", null: false
    t.index ["ativo_id"], name: "index_operacoes_on_ativo_id"
    t.index ["conta_investimento_id", "ativo_id"], name: "index_operacoes_on_conta_investimento_id_and_ativo_id"
    t.index ["conta_investimento_id"], name: "index_operacoes_on_conta_investimento_id"
    t.index ["evento_financeiro_id"], name: "index_operacoes_on_evento_financeiro_id", unique: true
    t.index ["moeda_id"], name: "index_operacoes_on_moeda_id"
    t.check_constraint "natureza::text = ANY (ARRAY['compra'::character varying::text, 'venda'::character varying::text])", name: "operacoes_natureza_valida"
    t.check_constraint "quantidade > 0::numeric AND preco_unitario > 0::numeric", name: "operacoes_valores_positivos"
    t.check_constraint "taxa >= 0::numeric AND emolumentos >= 0::numeric AND corretagem >= 0::numeric AND iss_iof >= 0::numeric AND irrf >= 0::numeric AND outros >= 0::numeric", name: "operacoes_custos_nao_negativos"
    t.check_constraint "taxa_conversao_base > 0::numeric AND taxa_conversao_fiscal > 0::numeric", name: "operacoes_cambio_positivo"
  end

  create_table "posicoes_atuais", force: :cascade do |t|
    t.bigint "ativo_id", null: false
    t.bigint "conta_investimento_id", null: false
    t.datetime "created_at", null: false
    t.decimal "custo_total", precision: 30, scale: 12, default: "0.0", null: false
    t.decimal "custo_total_base", precision: 30, scale: 12, default: "0.0", null: false
    t.decimal "quantidade", precision: 30, scale: 10, default: "0.0", null: false
    t.decimal "resultado_realizado", precision: 30, scale: 12, default: "0.0", null: false
    t.bigint "ultimo_evento_aplicado_id"
    t.datetime "updated_at", null: false
    t.bigint "versao", default: 0, null: false
    t.index ["ativo_id"], name: "index_posicoes_atuais_on_ativo_id"
    t.index ["conta_investimento_id", "ativo_id"], name: "idx_posicoes_atuais_unica", unique: true
    t.index ["conta_investimento_id"], name: "index_posicoes_atuais_on_conta_investimento_id"
    t.index ["ultimo_evento_aplicado_id"], name: "index_posicoes_atuais_on_ultimo_evento_aplicado_id"
    t.check_constraint "quantidade = 0::numeric AND custo_total = 0::numeric AND custo_total_base = 0::numeric OR quantidade <> 0::numeric", name: "posicoes_zeradas_sem_custo"
  end

  create_table "proventos", force: :cascade do |t|
    t.bigint "ativo_id", null: false
    t.bigint "conta_investimento_id", null: false
    t.datetime "created_at", null: false
    t.date "data_base", null: false
    t.date "data_pagamento", null: false
    t.bigint "evento_financeiro_id", null: false
    t.bigint "moeda_id", null: false
    t.decimal "quantidade_referencia", precision: 30, scale: 10, null: false
    t.decimal "taxa_conversao_base", precision: 24, scale: 12, default: "1.0", null: false
    t.decimal "taxa_conversao_fiscal", precision: 24, scale: 12, default: "1.0", null: false
    t.string "tipo", null: false
    t.decimal "tributos", precision: 30, scale: 12, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.decimal "valor_bruto", precision: 30, scale: 12, null: false
    t.decimal "valor_liquido", precision: 30, scale: 12, null: false
    t.index ["ativo_id"], name: "index_proventos_on_ativo_id"
    t.index ["conta_investimento_id"], name: "index_proventos_on_conta_investimento_id"
    t.index ["evento_financeiro_id"], name: "index_proventos_on_evento_financeiro_id", unique: true
    t.index ["moeda_id"], name: "index_proventos_on_moeda_id"
    t.check_constraint "quantidade_referencia >= 0::numeric AND valor_bruto >= 0::numeric AND tributos >= 0::numeric AND valor_liquido >= 0::numeric AND valor_liquido = (valor_bruto - tributos)", name: "proventos_valores_coerentes"
    t.check_constraint "taxa_conversao_base > 0::numeric AND taxa_conversao_fiscal > 0::numeric", name: "proventos_cambio_positivo"
    t.check_constraint "tipo::text = ANY (ARRAY['dividendo'::character varying::text, 'jcp'::character varying::text, 'rendimento'::character varying::text])", name: "proventos_tipo_valido"
  end

  create_table "referencias", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "descricao"
    t.string "nome", null: false
    t.datetime "updated_at", null: false
    t.index ["nome"], name: "index_referencias_on_nome", unique: true
  end

  create_table "resultados_operacoes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "custo_alocado", precision: 30, scale: 12, null: false
    t.decimal "custos_alocados", precision: 30, scale: 12, null: false
    t.bigint "operacao_id", null: false
    t.decimal "quantidade_encerrada", precision: 30, scale: 10, null: false
    t.decimal "resultado_realizado", precision: 30, scale: 12, null: false
    t.datetime "updated_at", null: false
    t.decimal "valor_alienacao", precision: 30, scale: 12, null: false
    t.index ["operacao_id"], name: "index_resultados_operacoes_on_operacao_id"
    t.check_constraint "quantidade_encerrada > 0::numeric AND custos_alocados >= 0::numeric", name: "resultados_operacoes_valores_validos"
  end

  create_table "resumos_diarios_carteira", force: :cascade do |t|
    t.bigint "carteira_id", null: false
    t.datetime "created_at", null: false
    t.date "data", null: false
    t.date "data_cotacoes_usadas"
    t.string "estado_completude", null: false
    t.decimal "fluxo_externo_liquido", precision: 30, scale: 12, default: "0.0", null: false
    t.decimal "patrimonio_final", precision: 30, scale: 12
    t.decimal "patrimonio_inicial", precision: 30, scale: 12
    t.decimal "resultado_diario", precision: 30, scale: 12
    t.decimal "twr_diario", precision: 24, scale: 12
    t.datetime "updated_at", null: false
    t.decimal "valor_ativos", precision: 30, scale: 12
    t.decimal "valor_caixa", precision: 30, scale: 12
    t.index ["carteira_id", "data"], name: "idx_resumos_diarios_unico", unique: true
    t.index ["carteira_id"], name: "index_resumos_diarios_carteira_on_carteira_id"
    t.check_constraint "estado_completude::text = ANY (ARRAY['completo'::character varying::text, 'incompleto'::character varying::text, 'sem_patrimonio_inicial'::character varying::text])", name: "resumos_estado_valido"
  end

  create_table "transferencias_caixa", force: :cascade do |t|
    t.bigint "conta_caixa_destino_id", null: false
    t.bigint "conta_caixa_origem_id", null: false
    t.datetime "created_at", null: false
    t.date "data_efetiva", null: false
    t.bigint "evento_financeiro_id", null: false
    t.datetime "updated_at", null: false
    t.decimal "valor", precision: 30, scale: 12, null: false
    t.index ["conta_caixa_destino_id"], name: "index_transferencias_caixa_on_conta_caixa_destino_id"
    t.index ["conta_caixa_origem_id"], name: "index_transferencias_caixa_on_conta_caixa_origem_id"
    t.index ["evento_financeiro_id"], name: "index_transferencias_caixa_on_evento_financeiro_id", unique: true
    t.check_constraint "conta_caixa_origem_id <> conta_caixa_destino_id", name: "transferencias_caixa_contas_distintas"
    t.check_constraint "valor > 0::numeric", name: "transferencias_caixa_valor_positivo"
  end

  create_table "transferencias_custodia", force: :cascade do |t|
    t.bigint "ativo_id", null: false
    t.bigint "conta_destino_id", null: false
    t.bigint "conta_origem_id", null: false
    t.datetime "created_at", null: false
    t.bigint "evento_financeiro_id", null: false
    t.decimal "quantidade", precision: 30, scale: 10, null: false
    t.datetime "updated_at", null: false
    t.index ["ativo_id"], name: "index_transferencias_custodia_on_ativo_id"
    t.index ["conta_destino_id"], name: "index_transferencias_custodia_on_conta_destino_id"
    t.index ["conta_origem_id"], name: "index_transferencias_custodia_on_conta_origem_id"
    t.index ["evento_financeiro_id"], name: "index_transferencias_custodia_on_evento_financeiro_id", unique: true
    t.check_constraint "conta_origem_id <> conta_destino_id", name: "transferencias_custodia_contas_distintas"
    t.check_constraint "quantidade > 0::numeric", name: "transferencias_custodia_quantidade_positiva"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "locked_at"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.integer "sign_in_count", default: 0, null: false
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "versoes_referencia", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "estado", default: "rascunho", null: false
    t.bigint "referencia_id", null: false
    t.datetime "updated_at", null: false
    t.date "vigencia_inicial", null: false
    t.index ["referencia_id", "vigencia_inicial"], name: "idx_versoes_referencia_vigencia", unique: true
    t.index ["referencia_id"], name: "index_versoes_referencia_on_referencia_id"
    t.check_constraint "estado::text = ANY (ARRAY['rascunho'::character varying::text, 'publicada'::character varying::text, 'encerrada'::character varying::text])", name: "versoes_referencia_estado_valido"
  end

  add_foreign_key "alocacoes_referencia", "ativos", on_delete: :restrict
  add_foreign_key "alocacoes_referencia", "versoes_referencia", column: "versao_referencia_id", on_delete: :restrict
  add_foreign_key "ativos", "moedas", column: "moeda_exposicao_id", on_delete: :restrict
  add_foreign_key "ativos", "moedas", column: "moeda_negociacao_id", on_delete: :restrict
  add_foreign_key "carteiras", "investidores", on_delete: :restrict
  add_foreign_key "carteiras", "moedas", column: "moeda_base_id", on_delete: :restrict
  add_foreign_key "contas_caixa", "contas_investimento", column: "conta_investimento_id", on_delete: :restrict
  add_foreign_key "contas_caixa", "moedas", on_delete: :restrict
  add_foreign_key "contas_investimento", "carteiras", on_delete: :restrict
  add_foreign_key "contas_investimento", "corretoras", on_delete: :restrict
  add_foreign_key "cotacoes_ativos", "ativos", on_delete: :restrict
  add_foreign_key "cotacoes_ativos", "fontes_cotacao", column: "fonte_cotacao_id", on_delete: :restrict
  add_foreign_key "cotacoes_ativos", "moedas", on_delete: :restrict
  add_foreign_key "cotacoes_ativos", "users", column: "usuario_responsavel_id", on_delete: :restrict
  add_foreign_key "cotacoes_cambio", "fontes_cotacao", column: "fonte_cotacao_id", on_delete: :restrict
  add_foreign_key "cotacoes_cambio", "moedas", column: "moeda_destino_id", on_delete: :restrict
  add_foreign_key "cotacoes_cambio", "moedas", column: "moeda_origem_id", on_delete: :restrict
  add_foreign_key "cotacoes_cambio", "users", column: "usuario_responsavel_id", on_delete: :restrict
  add_foreign_key "eventos_corporativos", "ativos", column: "ativo_destino_id", on_delete: :restrict
  add_foreign_key "eventos_corporativos", "ativos", column: "ativo_origem_id", on_delete: :restrict
  add_foreign_key "eventos_corporativos", "contas_investimento", column: "conta_investimento_id", on_delete: :restrict
  add_foreign_key "eventos_corporativos", "eventos_financeiros", column: "evento_financeiro_id", on_delete: :restrict
  add_foreign_key "eventos_corporativos", "moedas", on_delete: :restrict
  add_foreign_key "eventos_financeiros", "carteiras", on_delete: :restrict
  add_foreign_key "eventos_financeiros", "eventos_financeiros", column: "evento_revertido_id", on_delete: :restrict
  add_foreign_key "eventos_financeiros", "users", column: "usuario_responsavel_id", on_delete: :restrict
  add_foreign_key "importacoes_extrato", "contas_caixa", column: "conta_caixa_id", on_delete: :restrict
  add_foreign_key "importacoes_extrato", "corretoras", on_delete: :restrict
  add_foreign_key "investidores", "moedas", column: "moeda_fiscal_id", on_delete: :restrict
  add_foreign_key "investidores", "users", on_delete: :restrict
  add_foreign_key "itens_extrato_importado", "eventos_financeiros", column: "evento_financeiro_id", on_delete: :restrict
  add_foreign_key "itens_extrato_importado", "importacoes_extrato", column: "importacao_extrato_id", on_delete: :restrict
  add_foreign_key "itens_extrato_importado", "lancamentos_caixa", column: "lancamento_caixa_id", on_delete: :restrict
  add_foreign_key "itens_extrato_importado", "moedas", on_delete: :restrict
  add_foreign_key "itens_extrato_importado", "users", column: "usuario_responsavel_id", on_delete: :restrict
  add_foreign_key "lancamentos_caixa", "contas_caixa", column: "conta_caixa_id", on_delete: :restrict
  add_foreign_key "lancamentos_caixa", "eventos_financeiros", column: "evento_financeiro_id", on_delete: :restrict
  add_foreign_key "movimentacoes_caixa", "contas_caixa", column: "conta_caixa_id", on_delete: :restrict
  add_foreign_key "movimentacoes_caixa", "eventos_financeiros", column: "evento_financeiro_id", on_delete: :restrict
  add_foreign_key "operacoes", "ativos", on_delete: :restrict
  add_foreign_key "operacoes", "contas_investimento", column: "conta_investimento_id", on_delete: :restrict
  add_foreign_key "operacoes", "eventos_financeiros", column: "evento_financeiro_id", on_delete: :restrict
  add_foreign_key "operacoes", "moedas", on_delete: :restrict
  add_foreign_key "posicoes_atuais", "ativos", on_delete: :restrict
  add_foreign_key "posicoes_atuais", "contas_investimento", column: "conta_investimento_id", on_delete: :restrict
  add_foreign_key "posicoes_atuais", "eventos_financeiros", column: "ultimo_evento_aplicado_id", on_delete: :restrict
  add_foreign_key "proventos", "ativos", on_delete: :restrict
  add_foreign_key "proventos", "contas_investimento", column: "conta_investimento_id", on_delete: :restrict
  add_foreign_key "proventos", "eventos_financeiros", column: "evento_financeiro_id", on_delete: :restrict
  add_foreign_key "proventos", "moedas", on_delete: :restrict
  add_foreign_key "resultados_operacoes", "operacoes", on_delete: :restrict
  add_foreign_key "resumos_diarios_carteira", "carteiras", on_delete: :restrict
  add_foreign_key "transferencias_caixa", "contas_caixa", column: "conta_caixa_destino_id", on_delete: :restrict
  add_foreign_key "transferencias_caixa", "contas_caixa", column: "conta_caixa_origem_id", on_delete: :restrict
  add_foreign_key "transferencias_caixa", "eventos_financeiros", column: "evento_financeiro_id", on_delete: :restrict
  add_foreign_key "transferencias_custodia", "ativos", on_delete: :restrict
  add_foreign_key "transferencias_custodia", "contas_investimento", column: "conta_destino_id", on_delete: :restrict
  add_foreign_key "transferencias_custodia", "contas_investimento", column: "conta_origem_id", on_delete: :restrict
  add_foreign_key "transferencias_custodia", "eventos_financeiros", column: "evento_financeiro_id", on_delete: :restrict
  add_foreign_key "versoes_referencia", "referencias", on_delete: :restrict
end
