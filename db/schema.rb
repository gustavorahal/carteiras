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

ActiveRecord::Schema[8.1].define(version: 2026_08_13_190000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "ativos", force: :cascade do |t|
    t.datetime "arquivado_em"
    t.string "cnpj"
    t.string "codigo", null: false
    t.datetime "created_at", null: false
    t.string "descricao"
    t.string "mercado", null: false
    t.bigint "moeda_negociacao_id", null: false
    t.string "tipo", null: false
    t.datetime "updated_at", null: false
    t.index ["cnpj"], name: "index_ativos_on_cnpj"
    t.index ["codigo", "mercado"], name: "index_ativos_on_codigo_and_mercado", unique: true
    t.index ["moeda_negociacao_id"], name: "index_ativos_on_moeda_negociacao_id"
    t.check_constraint "cnpj IS NULL OR cnpj::text ~ '^[0-9]{14}$'::text", name: "ativos_cnpj_valido"
    t.check_constraint "codigo::text = upper(codigo::text) AND btrim(codigo::text) <> ''::text", name: "ativos_codigo_valido"
    t.check_constraint "mercado::text = upper(mercado::text) AND btrim(mercado::text) <> ''::text", name: "ativos_mercado_valido"
    t.check_constraint "tipo::text = ANY (ARRAY['acao'::character varying::text, 'fii'::character varying::text, 'fundo'::character varying::text, 'etf'::character varying::text, 'renda_fixa'::character varying::text, 'criptoativo'::character varying::text, 'outro'::character varying::text])", name: "ativos_tipo_valido"
  end

  create_table "carteiras", force: :cascade do |t|
    t.datetime "arquivado_em"
    t.datetime "created_at", null: false
    t.bigint "investidor_id", null: false
    t.bigint "moeda_base_id", null: false
    t.string "nome", null: false
    t.datetime "updated_at", null: false
    t.index "investidor_id, lower((nome)::text)", name: "idx_carteiras_investidor_nome", unique: true
    t.index ["investidor_id"], name: "index_carteiras_on_investidor_id"
    t.index ["moeda_base_id"], name: "index_carteiras_on_moeda_base_id"
    t.check_constraint "btrim(nome::text) <> ''::text", name: "carteiras_nome_preenchido"
  end

  create_table "contas_caixa", force: :cascade do |t|
    t.datetime "arquivado_em"
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
    t.datetime "created_at", null: false
    t.string "identificador_externo"
    t.bigint "instituicao_id", null: false
    t.string "nome", null: false
    t.datetime "updated_at", null: false
    t.index "carteira_id, lower((nome)::text)", name: "idx_contas_investimento_carteira_nome", unique: true
    t.index ["carteira_id"], name: "index_contas_investimento_on_carteira_id"
    t.index ["identificador_externo"], name: "index_contas_investimento_on_identificador_externo"
    t.index ["instituicao_id"], name: "index_contas_investimento_on_instituicao_id"
    t.check_constraint "btrim(nome::text) <> ''::text", name: "contas_investimento_nome_preenchido"
  end

  create_table "cotacoes_ativos", force: :cascade do |t|
    t.bigint "ativo_id", null: false
    t.bigint "autor_id"
    t.datetime "created_at", null: false
    t.date "data", null: false
    t.bigint "fonte_cotacao_id", null: false
    t.boolean "manual", default: false, null: false
    t.decimal "preco", precision: 30, scale: 12, null: false
    t.datetime "updated_at", null: false
    t.index ["ativo_id", "data"], name: "index_cotacoes_ativos_on_ativo_id_and_data", unique: true
    t.index ["ativo_id"], name: "index_cotacoes_ativos_on_ativo_id"
    t.index ["autor_id"], name: "index_cotacoes_ativos_on_autor_id"
    t.index ["fonte_cotacao_id"], name: "index_cotacoes_ativos_on_fonte_cotacao_id"
    t.check_constraint "manual AND autor_id IS NOT NULL OR NOT manual AND autor_id IS NULL", name: "cotacoes_ativos_autoria_valida"
    t.check_constraint "preco > 0::numeric", name: "cotacoes_ativos_preco_positivo"
  end

  create_table "cotacoes_cambio", force: :cascade do |t|
    t.bigint "autor_id", null: false
    t.datetime "created_at", null: false
    t.date "data", null: false
    t.bigint "fonte_cotacao_id", null: false
    t.bigint "moeda_destino_id", null: false
    t.bigint "moeda_origem_id", null: false
    t.decimal "taxa", precision: 24, scale: 12, null: false
    t.datetime "updated_at", null: false
    t.index ["autor_id"], name: "index_cotacoes_cambio_on_autor_id"
    t.index ["fonte_cotacao_id"], name: "index_cotacoes_cambio_on_fonte_cotacao_id"
    t.index ["moeda_destino_id"], name: "index_cotacoes_cambio_on_moeda_destino_id"
    t.index ["moeda_origem_id", "moeda_destino_id", "data"], name: "idx_cotacoes_cambio_par_data", unique: true
    t.index ["moeda_origem_id"], name: "index_cotacoes_cambio_on_moeda_origem_id"
    t.check_constraint "moeda_origem_id <> moeda_destino_id AND taxa > 0::numeric", name: "cotacoes_cambio_valida"
  end

  create_table "espacos", force: :cascade do |t|
    t.datetime "arquivado_em"
    t.datetime "created_at", null: false
    t.string "nome", null: false
    t.datetime "updated_at", null: false
    t.check_constraint "btrim(nome::text) <> ''::text", name: "espacos_nome_preenchido"
  end

  create_table "eventos_corporativos", force: :cascade do |t|
    t.bigint "ativo_destino_id"
    t.bigint "ativo_origem_id", null: false
    t.bigint "conta_investimento_id", null: false
    t.datetime "created_at", null: false
    t.decimal "quantidade_final", precision: 30, scale: 10, null: false
    t.string "tipo", null: false
    t.bigint "transacao_financeira_id", null: false
    t.datetime "updated_at", null: false
    t.index ["ativo_destino_id"], name: "index_eventos_corporativos_on_ativo_destino_id"
    t.index ["ativo_origem_id"], name: "index_eventos_corporativos_on_ativo_origem_id"
    t.index ["conta_investimento_id"], name: "index_eventos_corporativos_on_conta_investimento_id"
    t.index ["transacao_financeira_id"], name: "index_eventos_corporativos_on_transacao_financeira_id", unique: true
    t.check_constraint "(tipo::text = ANY (ARRAY['desdobramento'::character varying, 'grupamento'::character varying, 'bonificacao'::character varying]::text[])) AND ativo_destino_id IS NULL OR (tipo::text = ANY (ARRAY['conversao'::character varying, 'incorporacao'::character varying]::text[])) AND ativo_destino_id IS NOT NULL AND ativo_destino_id <> ativo_origem_id", name: "eventos_corporativos_ativos_validos"
    t.check_constraint "quantidade_final > 0::numeric", name: "eventos_corporativos_quantidade_valida"
    t.check_constraint "tipo::text = ANY (ARRAY['desdobramento'::character varying, 'grupamento'::character varying, 'bonificacao'::character varying, 'conversao'::character varying, 'incorporacao'::character varying]::text[])", name: "eventos_corporativos_tipo_valido"
  end

  create_table "fontes_cotacao", force: :cascade do |t|
    t.datetime "arquivado_em"
    t.string "codigo", null: false
    t.datetime "created_at", null: false
    t.string "nome", null: false
    t.datetime "updated_at", null: false
    t.index ["codigo"], name: "index_fontes_cotacao_on_codigo", unique: true
    t.check_constraint "btrim(nome::text) <> ''::text", name: "fontes_nome_preenchido"
    t.check_constraint "codigo::text = upper(codigo::text) AND btrim(codigo::text) <> ''::text", name: "fontes_codigo_valido"
  end

  create_table "importacoes_financeiras", force: :cascade do |t|
    t.bigint "autor_id", null: false
    t.string "checksum_sha256", null: false
    t.bigint "conta_investimento_id", null: false
    t.datetime "created_at", null: false
    t.jsonb "dados_extraidos", default: {}, null: false
    t.text "erro_resumido"
    t.string "estado", default: "pendente", null: false
    t.string "formato", null: false
    t.bigint "investidor_id", null: false
    t.string "nome_original", null: false
    t.datetime "updated_at", null: false
    t.string "versao_parser", null: false
    t.index ["autor_id"], name: "index_importacoes_financeiras_on_autor_id"
    t.index ["conta_investimento_id", "checksum_sha256"], name: "idx_importacoes_financeiras_checksum", unique: true
    t.index ["conta_investimento_id"], name: "index_importacoes_financeiras_on_conta_investimento_id"
    t.index ["investidor_id"], name: "index_importacoes_financeiras_on_investidor_id"
    t.check_constraint "estado::text = ANY (ARRAY['pendente'::character varying, 'analisada'::character varying, 'concluida'::character varying, 'falhou'::character varying]::text[])", name: "importacoes_financeiras_estado_valido"
  end

  create_table "instituicoes", force: :cascade do |t|
    t.datetime "arquivado_em"
    t.datetime "created_at", null: false
    t.string "nome", null: false
    t.datetime "updated_at", null: false
    t.index "lower((nome)::text)", name: "idx_instituicoes_nome", unique: true
    t.check_constraint "btrim(nome::text) <> ''::text", name: "instituicoes_nome_preenchido"
  end

  create_table "investidores", force: :cascade do |t|
    t.datetime "arquivado_em"
    t.datetime "created_at", null: false
    t.bigint "espaco_id", null: false
    t.string "nome", null: false
    t.datetime "updated_at", null: false
    t.index "espaco_id, lower((nome)::text)", name: "idx_investidores_espaco_nome", unique: true
    t.index ["espaco_id"], name: "index_investidores_on_espaco_id"
    t.check_constraint "btrim(nome::text) <> ''::text", name: "investidores_nome_preenchido"
  end

  create_table "lancamentos_caixa", force: :cascade do |t|
    t.bigint "conta_caixa_id", null: false
    t.datetime "created_at", null: false
    t.date "data_efetiva", null: false
    t.bigint "lancamento_original_id"
    t.string "natureza", null: false
    t.integer "ordem", null: false
    t.bigint "transacao_financeira_id", null: false
    t.datetime "updated_at", null: false
    t.decimal "valor", precision: 30, scale: 12, null: false
    t.index ["conta_caixa_id", "data_efetiva", "transacao_financeira_id"], name: "idx_lancamentos_saldo"
    t.index ["conta_caixa_id"], name: "index_lancamentos_caixa_on_conta_caixa_id"
    t.index ["lancamento_original_id"], name: "idx_lancamentos_reversao_unica", unique: true, where: "(lancamento_original_id IS NOT NULL)"
    t.index ["lancamento_original_id"], name: "index_lancamentos_caixa_on_lancamento_original_id"
    t.index ["transacao_financeira_id", "ordem"], name: "idx_lancamentos_transacao_ordem", unique: true
    t.index ["transacao_financeira_id"], name: "index_lancamentos_caixa_on_transacao_financeira_id"
    t.check_constraint "natureza::text = ANY (ARRAY['liquidacao_nota'::character varying::text, 'provento'::character varying::text, 'aporte'::character varying::text, 'resgate'::character varying::text, 'transferencia_saida'::character varying::text, 'transferencia_entrada'::character varying::text, 'cambio_saida'::character varying::text, 'cambio_entrada'::character varying::text])", name: "lancamentos_natureza_valida"
    t.check_constraint "ordem > 0 AND valor <> 0::numeric", name: "lancamentos_valores_validos"
  end

  create_table "membros_espaco", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "espaco_id", null: false
    t.string "papel", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["espaco_id", "user_id"], name: "index_membros_espaco_on_espaco_id_and_user_id", unique: true
    t.index ["espaco_id"], name: "index_membros_espaco_on_espaco_id"
    t.index ["user_id"], name: "index_membros_espaco_on_user_id"
    t.check_constraint "papel::text = ANY (ARRAY['administrador'::character varying::text, 'editor'::character varying::text, 'leitor'::character varying::text])", name: "membros_espaco_papel_valido"
  end

  create_table "moedas", force: :cascade do |t|
    t.datetime "arquivado_em"
    t.integer "casas_decimais", default: 2, null: false
    t.string "codigo", limit: 3, null: false
    t.datetime "created_at", null: false
    t.string "nome", null: false
    t.datetime "updated_at", null: false
    t.index ["codigo"], name: "index_moedas_on_codigo", unique: true
    t.check_constraint "btrim(nome::text) <> ''::text", name: "moedas_nome_preenchido"
    t.check_constraint "casas_decimais >= 0 AND casas_decimais <= 10", name: "moedas_casas_decimais_validas"
    t.check_constraint "codigo::text ~ '^[A-Z]{3}$'::text", name: "moedas_codigo_valido"
  end

  create_table "movimentacoes_caixa", force: :cascade do |t|
    t.bigint "conta_caixa_destino_id"
    t.bigint "conta_caixa_origem_id"
    t.datetime "created_at", null: false
    t.date "data_efetiva", null: false
    t.string "tipo", null: false
    t.bigint "transacao_financeira_id", null: false
    t.datetime "updated_at", null: false
    t.decimal "valor_destino", precision: 30, scale: 12
    t.decimal "valor_origem", precision: 30, scale: 12
    t.index ["conta_caixa_destino_id"], name: "index_movimentacoes_caixa_on_conta_caixa_destino_id"
    t.index ["conta_caixa_origem_id"], name: "index_movimentacoes_caixa_on_conta_caixa_origem_id"
    t.index ["transacao_financeira_id"], name: "index_movimentacoes_caixa_on_transacao_financeira_id", unique: true
    t.check_constraint "tipo::text <> 'transferencia'::text OR valor_origem = valor_destino", name: "movimentacoes_transferencia_valores_iguais"
    t.check_constraint "tipo::text = 'aporte'::text AND conta_caixa_origem_id IS NULL AND valor_origem IS NULL AND conta_caixa_destino_id IS NOT NULL AND valor_destino IS NOT NULL OR tipo::text = 'resgate'::text AND conta_caixa_origem_id IS NOT NULL AND valor_origem IS NOT NULL AND conta_caixa_destino_id IS NULL AND valor_destino IS NULL OR (tipo::text = ANY (ARRAY['transferencia'::character varying::text, 'cambio'::character varying::text])) AND conta_caixa_origem_id IS NOT NULL AND valor_origem IS NOT NULL AND conta_caixa_destino_id IS NOT NULL AND valor_destino IS NOT NULL AND conta_caixa_origem_id <> conta_caixa_destino_id", name: "movimentacoes_pernas_validas"
    t.check_constraint "tipo::text = ANY (ARRAY['aporte'::character varying::text, 'resgate'::character varying::text, 'transferencia'::character varying::text, 'cambio'::character varying::text])", name: "movimentacoes_tipo_valido"
    t.check_constraint "valor_destino IS NULL OR valor_destino > 0::numeric", name: "movimentacoes_valor_destino_positivo"
    t.check_constraint "valor_origem IS NULL OR valor_origem > 0::numeric", name: "movimentacoes_valor_origem_positivo"
  end

  create_table "negociacoes", force: :cascade do |t|
    t.bigint "ativo_id", null: false
    t.datetime "created_at", null: false
    t.decimal "custo_alocado", precision: 30, scale: 12, null: false
    t.string "natureza", null: false
    t.bigint "nota_negociacao_id", null: false
    t.integer "ordem", null: false
    t.decimal "preco_unitario", precision: 30, scale: 12, null: false
    t.decimal "quantidade", precision: 30, scale: 10, null: false
    t.datetime "updated_at", null: false
    t.index ["ativo_id"], name: "index_negociacoes_on_ativo_id"
    t.index ["nota_negociacao_id", "ordem"], name: "index_negociacoes_on_nota_negociacao_id_and_ordem", unique: true
    t.index ["nota_negociacao_id"], name: "index_negociacoes_on_nota_negociacao_id"
    t.check_constraint "natureza::text = ANY (ARRAY['compra'::character varying::text, 'venda'::character varying::text])", name: "negociacoes_natureza_valida"
    t.check_constraint "ordem > 0", name: "negociacoes_ordem_positiva"
    t.check_constraint "quantidade > 0::numeric AND preco_unitario > 0::numeric AND custo_alocado >= 0::numeric", name: "negociacoes_valores_validos"
  end

  create_table "notas_negociacao", force: :cascade do |t|
    t.bigint "conta_caixa_id", null: false
    t.datetime "created_at", null: false
    t.decimal "custo_operacional_total", precision: 30, scale: 12, default: "0.0", null: false
    t.date "data_liquidacao", null: false
    t.date "data_negociacao", null: false
    t.decimal "taxa_conversao_base", precision: 24, scale: 12, default: "1.0", null: false
    t.bigint "transacao_financeira_id", null: false
    t.datetime "updated_at", null: false
    t.index ["conta_caixa_id"], name: "index_notas_negociacao_on_conta_caixa_id"
    t.index ["transacao_financeira_id"], name: "index_notas_negociacao_on_transacao_financeira_id", unique: true
    t.check_constraint "custo_operacional_total >= 0::numeric AND taxa_conversao_base > 0::numeric", name: "notas_valores_validos"
    t.check_constraint "data_negociacao <= data_liquidacao", name: "notas_datas_validas"
  end

  create_table "posicoes_atuais", force: :cascade do |t|
    t.bigint "ativo_id", null: false
    t.bigint "conta_investimento_id", null: false
    t.datetime "created_at", null: false
    t.decimal "custo_total_base", precision: 30, scale: 12, null: false
    t.decimal "custo_total_local", precision: 30, scale: 12, null: false
    t.decimal "quantidade", precision: 30, scale: 10, null: false
    t.bigint "ultima_transacao_id", null: false
    t.datetime "updated_at", null: false
    t.index ["ativo_id"], name: "index_posicoes_atuais_on_ativo_id"
    t.index ["conta_investimento_id", "ativo_id"], name: "idx_posicoes_atuais_unica", unique: true
    t.index ["conta_investimento_id"], name: "index_posicoes_atuais_on_conta_investimento_id"
    t.index ["ultima_transacao_id"], name: "index_posicoes_atuais_on_ultima_transacao_id"
    t.check_constraint "quantidade > 0::numeric AND custo_total_local >= 0::numeric AND custo_total_base >= 0::numeric", name: "posicoes_valores_validos"
  end

  create_table "proventos", force: :cascade do |t|
    t.bigint "ativo_id", null: false
    t.bigint "conta_caixa_id", null: false
    t.datetime "created_at", null: false
    t.date "data_base", null: false
    t.date "data_pagamento", null: false
    t.decimal "quantidade_referencia", precision: 30, scale: 10, null: false
    t.decimal "retencoes", precision: 30, scale: 12, default: "0.0", null: false
    t.decimal "taxa_conversao_base", precision: 24, scale: 12, default: "1.0", null: false
    t.string "tipo", null: false
    t.bigint "transacao_financeira_id", null: false
    t.datetime "updated_at", null: false
    t.decimal "valor_bruto", precision: 30, scale: 12, null: false
    t.decimal "valor_liquido", precision: 30, scale: 12, null: false
    t.index ["ativo_id"], name: "index_proventos_on_ativo_id"
    t.index ["conta_caixa_id"], name: "index_proventos_on_conta_caixa_id"
    t.index ["transacao_financeira_id"], name: "index_proventos_on_transacao_financeira_id", unique: true
    t.check_constraint "quantidade_referencia >= 0::numeric AND valor_bruto >= 0::numeric AND retencoes >= 0::numeric AND valor_liquido >= 0::numeric AND valor_liquido = (valor_bruto - retencoes) AND taxa_conversao_base > 0::numeric", name: "proventos_valores_validos"
    t.check_constraint "tipo::text = ANY (ARRAY['dividendo'::character varying::text, 'jcp'::character varying::text, 'rendimento'::character varying::text, 'juros'::character varying::text, 'outro'::character varying::text])", name: "proventos_tipo_valido"
  end

  create_table "saldos_iniciais", force: :cascade do |t|
    t.bigint "ativo_id", null: false
    t.bigint "conta_investimento_id", null: false
    t.datetime "created_at", null: false
    t.decimal "custo_total_base", precision: 30, scale: 12, null: false
    t.decimal "custo_total_local", precision: 30, scale: 12, null: false
    t.string "fonte_custo", default: "manual", null: false
    t.decimal "preco_medio_base_informado", precision: 30, scale: 12
    t.decimal "preco_medio_local_informado", precision: 30, scale: 12
    t.decimal "quantidade", precision: 30, scale: 10, null: false
    t.bigint "transacao_financeira_id", null: false
    t.datetime "updated_at", null: false
    t.index ["ativo_id"], name: "index_saldos_iniciais_on_ativo_id"
    t.index ["conta_investimento_id"], name: "index_saldos_iniciais_on_conta_investimento_id"
    t.index ["transacao_financeira_id"], name: "index_saldos_iniciais_on_transacao_financeira_id", unique: true
    t.check_constraint "fonte_custo::text = ANY (ARRAY['manual'::character varying, 'xp'::character varying, 'avenue'::character varying, 'planilha'::character varying, 'outra'::character varying]::text[])", name: "saldos_iniciais_fonte_custo_valida"
    t.check_constraint "preco_medio_local_informado IS NULL AND preco_medio_base_informado IS NULL OR preco_medio_local_informado > 0::numeric AND preco_medio_base_informado > 0::numeric", name: "saldos_iniciais_precos_medios_validos"
    t.check_constraint "quantidade > 0::numeric AND custo_total_local >= 0::numeric AND custo_total_base >= 0::numeric", name: "saldos_iniciais_valores_validos"
  end

  create_table "transacoes_financeiras", force: :cascade do |t|
    t.string "chave_idempotencia"
    t.datetime "confirmada_em"
    t.bigint "confirmado_por_id"
    t.datetime "created_at", null: false
    t.bigint "criado_por_id", null: false
    t.date "data_competencia", null: false
    t.string "estado", default: "rascunho", null: false
    t.bigint "importacao_financeira_id"
    t.bigint "investidor_id", null: false
    t.text "observacao"
    t.integer "ordem_na_data"
    t.string "origem", null: false
    t.string "tipo", null: false
    t.bigint "transacao_revertida_id"
    t.datetime "updated_at", null: false
    t.index ["confirmado_por_id"], name: "index_transacoes_financeiras_on_confirmado_por_id"
    t.index ["criado_por_id"], name: "index_transacoes_financeiras_on_criado_por_id"
    t.index ["importacao_financeira_id"], name: "index_transacoes_financeiras_on_importacao_financeira_id"
    t.index ["investidor_id", "chave_idempotencia"], name: "idx_transacoes_idempotencia", unique: true, where: "(chave_idempotencia IS NOT NULL)"
    t.index ["investidor_id", "data_competencia", "ordem_na_data", "id"], name: "idx_transacoes_replay"
    t.index ["investidor_id"], name: "index_transacoes_financeiras_on_investidor_id"
    t.index ["transacao_revertida_id"], name: "idx_transacoes_reversao_unica", unique: true, where: "(transacao_revertida_id IS NOT NULL)"
    t.index ["transacao_revertida_id"], name: "index_transacoes_financeiras_on_transacao_revertida_id"
    t.check_constraint "estado::text = 'rascunho'::text AND confirmado_por_id IS NULL AND confirmada_em IS NULL OR estado::text = 'confirmada'::text AND confirmado_por_id IS NOT NULL AND confirmada_em IS NOT NULL AND ordem_na_data IS NOT NULL", name: "transacoes_estado_estrutural"
    t.check_constraint "estado::text = ANY (ARRAY['rascunho'::character varying::text, 'confirmada'::character varying::text])", name: "transacoes_estado_valido"
    t.check_constraint "ordem_na_data IS NULL OR ordem_na_data > 0", name: "transacoes_ordem_positiva"
    t.check_constraint "origem::text = ANY (ARRAY['manual'::character varying, 'importacao'::character varying, 'sistema'::character varying]::text[])", name: "transacoes_origem_valida"
    t.check_constraint "tipo::text = 'reversao'::text AND transacao_revertida_id IS NOT NULL AND origem::text = 'sistema'::text AND estado::text = 'confirmada'::text OR tipo::text <> 'reversao'::text AND transacao_revertida_id IS NULL", name: "transacoes_reversao_estrutural"
    t.check_constraint "tipo::text = ANY (ARRAY['nota_negociacao'::character varying, 'provento'::character varying, 'movimentacao_caixa'::character varying, 'saldo_inicial'::character varying, 'transferencia_custodia'::character varying, 'evento_corporativo'::character varying, 'reversao'::character varying]::text[])", name: "transacoes_tipo_valido"
  end

  create_table "transferencias_custodia", force: :cascade do |t|
    t.bigint "ativo_id", null: false
    t.bigint "conta_destino_id", null: false
    t.bigint "conta_origem_id", null: false
    t.datetime "created_at", null: false
    t.decimal "quantidade", precision: 30, scale: 10, null: false
    t.bigint "transacao_financeira_id", null: false
    t.datetime "updated_at", null: false
    t.index ["ativo_id"], name: "index_transferencias_custodia_on_ativo_id"
    t.index ["conta_destino_id"], name: "index_transferencias_custodia_on_conta_destino_id"
    t.index ["conta_origem_id"], name: "index_transferencias_custodia_on_conta_origem_id"
    t.index ["transacao_financeira_id"], name: "index_transferencias_custodia_on_transacao_financeira_id", unique: true
    t.check_constraint "conta_origem_id <> conta_destino_id AND quantidade > 0::numeric", name: "transferencias_custodia_valores_validos"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "administrador_sistema", default: false, null: false
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
    t.integer "sign_in_count", default: 0, null: false
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "ativos", "moedas", column: "moeda_negociacao_id", on_delete: :restrict
  add_foreign_key "carteiras", "investidores", on_delete: :restrict
  add_foreign_key "carteiras", "moedas", column: "moeda_base_id", on_delete: :restrict
  add_foreign_key "contas_caixa", "contas_investimento", column: "conta_investimento_id", on_delete: :restrict
  add_foreign_key "contas_caixa", "moedas", on_delete: :restrict
  add_foreign_key "contas_investimento", "carteiras", on_delete: :restrict
  add_foreign_key "contas_investimento", "instituicoes", on_delete: :restrict
  add_foreign_key "cotacoes_ativos", "ativos", on_delete: :restrict
  add_foreign_key "cotacoes_ativos", "fontes_cotacao", column: "fonte_cotacao_id", on_delete: :restrict
  add_foreign_key "cotacoes_ativos", "users", column: "autor_id", on_delete: :restrict
  add_foreign_key "cotacoes_cambio", "fontes_cotacao", column: "fonte_cotacao_id", on_delete: :restrict
  add_foreign_key "cotacoes_cambio", "moedas", column: "moeda_destino_id", on_delete: :restrict
  add_foreign_key "cotacoes_cambio", "moedas", column: "moeda_origem_id", on_delete: :restrict
  add_foreign_key "cotacoes_cambio", "users", column: "autor_id", on_delete: :restrict
  add_foreign_key "eventos_corporativos", "ativos", column: "ativo_destino_id", on_delete: :restrict
  add_foreign_key "eventos_corporativos", "ativos", column: "ativo_origem_id", on_delete: :restrict
  add_foreign_key "eventos_corporativos", "contas_investimento", column: "conta_investimento_id", on_delete: :restrict
  add_foreign_key "eventos_corporativos", "transacoes_financeiras", column: "transacao_financeira_id", on_delete: :restrict
  add_foreign_key "importacoes_financeiras", "contas_investimento", column: "conta_investimento_id", on_delete: :restrict
  add_foreign_key "importacoes_financeiras", "investidores", on_delete: :restrict
  add_foreign_key "importacoes_financeiras", "users", column: "autor_id", on_delete: :restrict
  add_foreign_key "investidores", "espacos", on_delete: :restrict
  add_foreign_key "lancamentos_caixa", "contas_caixa", column: "conta_caixa_id", on_delete: :restrict
  add_foreign_key "lancamentos_caixa", "lancamentos_caixa", column: "lancamento_original_id", on_delete: :restrict
  add_foreign_key "lancamentos_caixa", "transacoes_financeiras", column: "transacao_financeira_id", on_delete: :restrict
  add_foreign_key "membros_espaco", "espacos", on_delete: :restrict
  add_foreign_key "membros_espaco", "users", on_delete: :restrict
  add_foreign_key "movimentacoes_caixa", "contas_caixa", column: "conta_caixa_destino_id", on_delete: :restrict
  add_foreign_key "movimentacoes_caixa", "contas_caixa", column: "conta_caixa_origem_id", on_delete: :restrict
  add_foreign_key "movimentacoes_caixa", "transacoes_financeiras", column: "transacao_financeira_id", on_delete: :restrict
  add_foreign_key "negociacoes", "ativos", on_delete: :restrict
  add_foreign_key "negociacoes", "notas_negociacao", column: "nota_negociacao_id", on_delete: :restrict
  add_foreign_key "notas_negociacao", "contas_caixa", column: "conta_caixa_id", on_delete: :restrict
  add_foreign_key "notas_negociacao", "transacoes_financeiras", column: "transacao_financeira_id", on_delete: :restrict
  add_foreign_key "posicoes_atuais", "ativos", on_delete: :restrict
  add_foreign_key "posicoes_atuais", "contas_investimento", column: "conta_investimento_id", on_delete: :restrict
  add_foreign_key "posicoes_atuais", "transacoes_financeiras", column: "ultima_transacao_id", on_delete: :restrict
  add_foreign_key "proventos", "ativos", on_delete: :restrict
  add_foreign_key "proventos", "contas_caixa", column: "conta_caixa_id", on_delete: :restrict
  add_foreign_key "proventos", "transacoes_financeiras", column: "transacao_financeira_id", on_delete: :restrict
  add_foreign_key "saldos_iniciais", "ativos", on_delete: :restrict
  add_foreign_key "saldos_iniciais", "contas_investimento", column: "conta_investimento_id", on_delete: :restrict
  add_foreign_key "saldos_iniciais", "transacoes_financeiras", column: "transacao_financeira_id", on_delete: :restrict
  add_foreign_key "transacoes_financeiras", "importacoes_financeiras", column: "importacao_financeira_id", on_delete: :restrict
  add_foreign_key "transacoes_financeiras", "investidores", on_delete: :restrict
  add_foreign_key "transacoes_financeiras", "transacoes_financeiras", column: "transacao_revertida_id", on_delete: :restrict
  add_foreign_key "transacoes_financeiras", "users", column: "confirmado_por_id", on_delete: :restrict
  add_foreign_key "transacoes_financeiras", "users", column: "criado_por_id", on_delete: :restrict
  add_foreign_key "transferencias_custodia", "ativos", on_delete: :restrict
  add_foreign_key "transferencias_custodia", "contas_investimento", column: "conta_destino_id", on_delete: :restrict
  add_foreign_key "transferencias_custodia", "contas_investimento", column: "conta_origem_id", on_delete: :restrict
  add_foreign_key "transferencias_custodia", "transacoes_financeiras", column: "transacao_financeira_id", on_delete: :restrict
end
