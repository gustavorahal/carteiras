class AdicionarPrecoMedioAoSaldoInicial < ActiveRecord::Migration[8.1]
  def change
    add_column :saldos_iniciais, :preco_medio_local_informado, :decimal, precision: 30, scale: 12
    add_column :saldos_iniciais, :preco_medio_base_informado, :decimal, precision: 30, scale: 12
    add_column :saldos_iniciais, :fonte_custo, :string, null: false, default: "manual"

    add_check_constraint :saldos_iniciais,
      "(preco_medio_local_informado IS NULL AND preco_medio_base_informado IS NULL) OR " \
        "(preco_medio_local_informado > 0 AND preco_medio_base_informado > 0)",
      name: "saldos_iniciais_precos_medios_validos"
    add_check_constraint :saldos_iniciais,
      "fonte_custo IN ('manual', 'xp', 'avenue', 'planilha', 'outra')",
      name: "saldos_iniciais_fonte_custo_valida"
  end
end
