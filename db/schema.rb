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

ActiveRecord::Schema[8.1].define(version: 2026_07_09_130000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "ativos", force: :cascade do |t|
    t.string "cnpj"
    t.datetime "created_at", null: false
    t.string "descricao"
    t.string "moeda_exposicao"
    t.string "moeda_negociacao", null: false
    t.string "nome"
    t.integer "tipo"
    t.datetime "updated_at", null: false
    t.index ["cnpj"], name: "index_ativos_on_cnpj"
    t.index ["nome"], name: "ativos_nome_uindex", unique: true
  end

  create_table "carteiras", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "investidor_id", default: 1, null: false
    t.string "nome"
    t.bigint "referencia_id"
    t.datetime "updated_at", null: false
    t.index ["investidor_id"], name: "index_carteiras_on_investidor_id"
    t.index ["referencia_id"], name: "index_carteiras_on_referencia_id"
  end

  create_table "configs", force: :cascade do |t|
    t.string "nome"
    t.string "valor"
  end

  create_table "conta_correntes", force: :cascade do |t|
    t.bigint "carteira_id"
    t.bigint "corretora_id", null: false
    t.datetime "created_at", null: false
    t.string "moeda", null: false
    t.datetime "updated_at", null: false
    t.index ["carteira_id", "corretora_id", "moeda"], name: "index_cc_on_carteira_id_and_corretora_id_and_moeda", unique: true
    t.index ["carteira_id"], name: "index_conta_correntes_on_carteira_id"
    t.index ["corretora_id"], name: "index_conta_correntes_on_corretora_id"
  end

  create_table "corretoras", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "nome", null: false
    t.datetime "updated_at", null: false
  end

  create_table "cotacoes", force: :cascade do |t|
    t.bigint "ativo_id", null: false
    t.datetime "created_at", null: false
    t.date "data", null: false
    t.integer "fonte"
    t.datetime "updated_at", null: false
    t.decimal "valor_unit", precision: 30, scale: 12
    t.index ["ativo_id", "data"], name: "index_cotacoes_on_ativo_id_and_data", unique: true
    t.index ["ativo_id"], name: "index_cotacoes_on_ativo_id"
  end

  create_table "extratos", force: :cascade do |t|
    t.bigint "conta_corrente_id", null: false
    t.datetime "created_at", default: -> { "now()" }, null: false
    t.string "descricao", null: false
    t.date "liquidacao", null: false
    t.date "movimentacao", null: false
    t.boolean "processado", default: false
    t.decimal "saldo", precision: 19, scale: 4
    t.boolean "temporario", default: false, null: false
    t.datetime "updated_at", default: -> { "now()" }, null: false
    t.decimal "valor", precision: 19, scale: 4, null: false
    t.index ["conta_corrente_id"], name: "index_extratos_on_conta_corrente_id"
  end

  create_table "investidores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "nome", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_investidores_on_user_id"
  end

  create_table "movimentacoes", force: :cascade do |t|
    t.bigint "carteira_id", null: false
    t.bigint "corretora_id", null: false
    t.datetime "created_at", null: false
    t.date "data", null: false
    t.bigint "extrato_id"
    t.string "moeda", default: "BRL", null: false
    t.datetime "updated_at", null: false
    t.decimal "valor", precision: 19, scale: 4, null: false
    t.index ["carteira_id"], name: "index_movimentacoes_on_carteira_id"
    t.index ["corretora_id"], name: "index_movimentacoes_on_corretora_id"
    t.index ["extrato_id"], name: "index_movimentacoes_on_extrato_id"
  end

  create_table "operacoes", force: :cascade do |t|
    t.bigint "ativo_id"
    t.bigint "carteira_id"
    t.decimal "co_corretagem", precision: 19, scale: 4, default: "0.0"
    t.decimal "co_emolumentos", precision: 19, scale: 4, default: "0.0"
    t.decimal "co_irrf", precision: 19, scale: 4, default: "0.0"
    t.decimal "co_iss_iof", precision: 19, scale: 4, default: "0.0"
    t.decimal "co_outros", precision: 19, scale: 4, default: "0.0"
    t.decimal "co_taxa", precision: 19, scale: 4, default: "0.0"
    t.bigint "corretora_id", null: false
    t.datetime "created_at", null: false
    t.date "data", null: false
    t.integer "mon_ou_des"
    t.string "observacao"
    t.integer "operacao", null: false
    t.boolean "operacao_sys", default: false
    t.decimal "quantidade", precision: 30, scale: 10, null: false
    t.datetime "updated_at", null: false
    t.decimal "usdbrl", precision: 20, scale: 10, default: "1.0"
    t.decimal "valor_unit", precision: 30, scale: 12, null: false
    t.index ["ativo_id"], name: "index_operacoes_on_ativo_id"
    t.index ["carteira_id"], name: "index_operacoes_on_carteira_id"
  end

  create_table "proventos", force: :cascade do |t|
    t.bigint "ativo_id", null: false
    t.bigint "carteira_id", null: false
    t.bigint "corretora_id", null: false
    t.datetime "created_at", null: false
    t.date "data", null: false
    t.integer "evento", null: false
    t.bigint "extrato_id"
    t.string "moeda", default: "BRL", null: false
    t.decimal "quantidade", precision: 30, scale: 10, null: false
    t.datetime "updated_at", null: false
    t.decimal "valor_liquido", precision: 19, scale: 4, null: false
    t.index ["ativo_id"], name: "index_proventos_on_ativo_id"
    t.index ["carteira_id"], name: "index_proventos_on_carteira_id"
    t.index ["corretora_id"], name: "index_proventos_on_corretora_id"
    t.index ["extrato_id"], name: "index_proventos_on_extrato_id"
  end

  create_table "referencia_ativos", force: :cascade do |t|
    t.bigint "ativo_id", null: false
    t.string "book", null: false
    t.datetime "created_at", null: false
    t.date "data_entrada", default: -> { "now()" }, null: false
    t.date "data_saida"
    t.decimal "porcentagem", precision: 9, scale: 4, default: "0.0", null: false
    t.bigint "referencia_id", null: false
    t.datetime "updated_at", null: false
    t.index ["ativo_id"], name: "index_referencia_ativos_on_ativo_id"
    t.index ["referencia_id"], name: "index_referencia_ativos_on_referencia_id"
  end

  create_table "referencias", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "descricao"
    t.string "nome", null: false
    t.datetime "updated_at", null: false
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
    t.integer "role"
    t.integer "sign_in_count", default: 0, null: false
    t.string "unlock_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "carteiras", "investidores"
  add_foreign_key "carteiras", "referencias"
  add_foreign_key "conta_correntes", "carteiras"
  add_foreign_key "cotacoes", "ativos"
  add_foreign_key "extratos", "conta_correntes"
  add_foreign_key "investidores", "users"
  add_foreign_key "movimentacoes", "carteiras"
  add_foreign_key "movimentacoes", "corretoras"
  add_foreign_key "movimentacoes", "extratos"
  add_foreign_key "operacoes", "ativos"
  add_foreign_key "operacoes", "carteiras"
  add_foreign_key "operacoes", "corretoras", name: "operacoes_corretoras_id_fk"
  add_foreign_key "proventos", "ativos"
  add_foreign_key "proventos", "carteiras"
  add_foreign_key "proventos", "corretoras"
  add_foreign_key "proventos", "extratos"
  add_foreign_key "referencia_ativos", "ativos"
  add_foreign_key "referencia_ativos", "referencias"
end
