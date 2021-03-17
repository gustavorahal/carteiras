class DropInvestidorFromContaCorrente < ActiveRecord::Migration[6.0]
  def change
    remove_column :conta_correntes, :investidor_id
  end
end
