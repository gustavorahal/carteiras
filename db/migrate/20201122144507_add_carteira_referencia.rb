class AddCarteiraReferencia < ActiveRecord::Migration[6.0]
  def change
    add_reference :carteiras, :referencia, foreign_key: true
  end
end
