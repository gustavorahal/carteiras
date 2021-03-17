class AddCarteiraToContaCorrente < ActiveRecord::Migration[6.0]
  def change
    add_reference :conta_correntes, :carteira, foreign_key: true
  end
end
