class PermitirCustoDesconhecido < ActiveRecord::Migration[8.1]
  def change
    remove_check_constraint :saldos_iniciais, name: "saldos_iniciais_valores_validos"
    change_column_null :saldos_iniciais, :custo_total_local, true
    change_column_null :saldos_iniciais, :custo_total_base, true
    add_check_constraint :saldos_iniciais,
      "quantidade > 0 AND ((custo_total_local IS NULL AND custo_total_base IS NULL) OR " \
        "(custo_total_local >= 0 AND custo_total_base >= 0))",
      name: "saldos_iniciais_valores_validos"

    remove_check_constraint :posicoes_atuais, name: "posicoes_valores_validos"
    change_column_null :posicoes_atuais, :custo_total_local, true
    change_column_null :posicoes_atuais, :custo_total_base, true
    add_check_constraint :posicoes_atuais,
      "quantidade > 0 AND ((custo_total_local IS NULL AND custo_total_base IS NULL) OR " \
        "(custo_total_local >= 0 AND custo_total_base >= 0))",
      name: "posicoes_valores_validos"
  end
end
