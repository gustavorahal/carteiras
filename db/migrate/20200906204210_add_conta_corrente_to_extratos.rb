class AddContaCorrenteToExtratos < ActiveRecord::Migration[6.0]
  def change
    add_reference :extratos, :conta_corrente, foreign_key: true
  end
end
