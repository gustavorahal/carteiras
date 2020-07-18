# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_07_18_010443) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "ativos", force: :cascade do |t|
    t.string "nome"
    t.integer "tipo"
    t.string "moeda"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "descricao"
  end

  create_table "carteira_ativos", force: :cascade do |t|
    t.bigint "carteira_id", null: false
    t.bigint "ativo_id", null: false
    t.string "book"
    t.float "porcentagem"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["ativo_id"], name: "index_carteira_ativos_on_ativo_id"
    t.index ["carteira_id"], name: "index_carteira_ativos_on_carteira_id"
  end

  create_table "carteiras", force: :cascade do |t|
    t.string "nome"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "investidor_id", default: 1, null: false
    t.index ["investidor_id"], name: "index_carteiras_on_investidor_id"
  end

  create_table "cotacoes", force: :cascade do |t|
    t.bigint "ativo_id", null: false
    t.float "valor_unit"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "data"
    t.index ["ativo_id"], name: "index_cotacoes_on_ativo_id"
  end

  create_table "extratos", id: false, force: :cascade do |t|
    t.bigserial "id", null: false
    t.bigint "investidor_id", null: false
    t.string "corretora", null: false
    t.date "liquidacao", null: false
    t.date "movimentacao", null: false
    t.string "descricao", null: false
    t.float "valor", null: false
    t.string "moeda", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["investidor_id"], name: "index_extratos_on_investidor_id"
  end

  create_table "investidores", force: :cascade do |t|
    t.string "nome", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "operacoes", id: :bigint, default: -> { "nextval('trades_id_seq'::regclass)" }, force: :cascade do |t|
    t.bigint "ativo_id", null: false
    t.bigint "carteira_id", null: false
    t.date "data", null: false
    t.string "corretora", null: false
    t.integer "mon_ou_des"
    t.integer "operacao", null: false
    t.float "quantidade", null: false
    t.float "valor_unit", null: false
    t.float "co_taxa"
    t.float "co_emolumentos"
    t.float "co_corretagem"
    t.float "co_iss_iof"
    t.float "co_irrf"
    t.float "co_outros"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.float "usdbrl", default: 1.0
    t.bigint "carteira_ativos_id", default: 1, null: false
    t.index ["ativo_id"], name: "index_trades_on_ativo_id"
    t.index ["carteira_ativos_id"], name: "index_operacoes_on_carteira_ativos_id"
    t.index ["carteira_id"], name: "index_trades_on_carteira_id"
  end

  add_foreign_key "carteira_ativos", "ativos"
  add_foreign_key "carteira_ativos", "carteiras"
  add_foreign_key "carteiras", "investidores"
  add_foreign_key "cotacoes", "ativos"
  add_foreign_key "extratos", "investidores"
  add_foreign_key "operacoes", "ativos"
  add_foreign_key "operacoes", "carteira_ativos", column: "carteira_ativos_id"
  add_foreign_key "operacoes", "carteiras"
end
