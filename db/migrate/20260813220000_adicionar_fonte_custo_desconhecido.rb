class AdicionarFonteCustoDesconhecido < ActiveRecord::Migration[8.1]
  def change
    remove_check_constraint :saldos_iniciais, name: "saldos_iniciais_fonte_custo_valida"
    add_check_constraint :saldos_iniciais,
      "fonte_custo IN ('manual', 'xp', 'avenue', 'planilha', 'outra', 'desconhecido')",
      name: "saldos_iniciais_fonte_custo_valida"
  end
end
