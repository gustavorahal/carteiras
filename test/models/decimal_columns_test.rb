require 'test_helper'

class DecimalColumnsTest < ActiveSupport::TestCase
  EXPECTED_DECIMALS = {
    Cotacao => {
      valor_unit: [30, 12]
    },
    Extrato => {
      valor: [19, 4],
      saldo: [19, 4]
    },
    Movimentacao => {
      valor: [19, 4]
    },
    Operacao => {
      quantidade: [30, 10],
      valor_unit: [30, 12],
      co_taxa: [19, 4],
      co_emolumentos: [19, 4],
      co_corretagem: [19, 4],
      co_iss_iof: [19, 4],
      co_irrf: [19, 4],
      co_outros: [19, 4],
      usdbrl: [20, 10]
    },
    Provento => {
      quantidade: [30, 10],
      valor_liquido: [19, 4]
    },
    ReferenciaAtivo => {
      porcentagem: [9, 4]
    }
  }.freeze

  test 'valores financeiros, quantidades e percentuais usam decimal' do
    EXPECTED_DECIMALS.each do |model, columns|
      columns.each do |column_name, precision_and_scale|
        precision, scale = precision_and_scale
        column = model.column_for_attribute(column_name)

        assert_equal :decimal, column.type, "#{model}.#{column_name} deve usar decimal"
        assert_equal precision, column.precision, "#{model}.#{column_name} deve preservar precision"
        assert_equal scale, column.scale, "#{model}.#{column_name} deve preservar scale"
      end
    end
  end
end
