class ConvertFinancialFloatsToDecimals < ActiveRecord::Migration[8.1]
  MONEY = { precision: 19, scale: 4 }.freeze
  PRICE = { precision: 30, scale: 12 }.freeze
  QUANTITY = { precision: 30, scale: 10 }.freeze
  RATE = { precision: 20, scale: 10 }.freeze
  PERCENTAGE = { precision: 9, scale: 4 }.freeze

  def up
    decimal_column :cotacoes, :valor_unit, PRICE

    decimal_column :extratos, :valor, MONEY, null: false
    decimal_column :extratos, :saldo, MONEY

    decimal_column :movimentacoes, :valor, MONEY, null: false

    decimal_column :operacoes, :quantidade, QUANTITY, null: false
    decimal_column :operacoes, :valor_unit, PRICE, null: false
    decimal_column :operacoes, :co_taxa, MONEY, default: 0
    decimal_column :operacoes, :co_emolumentos, MONEY, default: 0
    decimal_column :operacoes, :co_corretagem, MONEY, default: 0
    decimal_column :operacoes, :co_iss_iof, MONEY, default: 0
    decimal_column :operacoes, :co_irrf, MONEY, default: 0
    decimal_column :operacoes, :co_outros, MONEY, default: 0
    decimal_column :operacoes, :usdbrl, RATE, default: 1

    decimal_column :proventos, :quantidade, QUANTITY, null: false
    decimal_column :proventos, :valor_liquido, MONEY, null: false

    decimal_column :referencia_ativos, :porcentagem, PERCENTAGE, default: 0, null: false
  end

  def down
    float_column :cotacoes, :valor_unit

    float_column :extratos, :valor, null: false
    float_column :extratos, :saldo

    float_column :movimentacoes, :valor, null: false

    float_column :operacoes, :quantidade, null: false
    float_column :operacoes, :valor_unit, null: false
    float_column :operacoes, :co_taxa, default: 0
    float_column :operacoes, :co_emolumentos, default: 0
    float_column :operacoes, :co_corretagem, default: 0
    float_column :operacoes, :co_iss_iof, default: 0
    float_column :operacoes, :co_irrf, default: 0
    float_column :operacoes, :co_outros, default: 0
    float_column :operacoes, :usdbrl, default: 1

    float_column :proventos, :quantidade, null: false
    float_column :proventos, :valor_liquido, null: false

    float_column :referencia_ativos, :porcentagem, default: 0, null: false
  end

  private

  def decimal_column(table, column, options, **column_options)
    change_column table, column, :decimal,
                  **options,
                  **column_options,
                  using: "ROUND(#{column}::numeric, #{options.fetch(:scale)})"
  end

  def float_column(table, column, **column_options)
    change_column table, column, :float,
                  **column_options,
                  using: "#{column}::double precision"
  end
end
