class AddSaldoToExtrato < ActiveRecord::Migration[6.1]
  def change
    add_column :extratos, :saldo, :float
  end
end
