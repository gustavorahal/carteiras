class CreateOperacoes < ActiveRecord::Migration[6.0]
  def change
    create_table :operacoes do |t|
      t.references :carteira_ativo, null: false, foreign_key: true
      t.date :data, { null: false }
      t.string :corretora, { null: false }
      t.integer :mon_ou_des
      t.integer :operacao, { null: false }
      t.float :quantidade, { null: false }
      t.float :valor_unit, { null: false }
      t.float :usdbrl, { default: 1 }
      t.float :co_taxa
      t.float :co_emolumentos
      t.float :co_corretagem
      t.float :co_iss_iof
      t.float :co_irrf
      t.float :co_outros

      t.timestamps
    end
  end
end
