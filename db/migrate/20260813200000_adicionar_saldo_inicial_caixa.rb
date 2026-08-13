class AdicionarSaldoInicialCaixa < ActiveRecord::Migration[8.0]
  def change
    create_table :saldos_iniciais_caixa do |t|
      t.references :transacao_financeira, null: false, index: { unique: true },
        foreign_key: { to_table: :transacoes_financeiras, on_delete: :restrict }
      t.references :conta_caixa, null: false,
        foreign_key: { to_table: :contas_caixa, on_delete: :restrict }
      t.decimal :valor, precision: 30, scale: 12, null: false
      t.timestamps
    end
    add_check_constraint :saldos_iniciais_caixa, "valor <> 0", name: "saldos_iniciais_caixa_valor_valido"

    remove_check_constraint :transacoes_financeiras, name: "transacoes_tipo_valido"
    add_check_constraint :transacoes_financeiras,
      "tipo IN ('nota_negociacao', 'provento', 'movimentacao_caixa', 'saldo_inicial', " \
        "'saldo_inicial_caixa', 'transferencia_custodia', 'evento_corporativo', 'reversao')",
      name: "transacoes_tipo_valido"

    remove_check_constraint :lancamentos_caixa, name: "lancamentos_natureza_valida"
    add_check_constraint :lancamentos_caixa,
      "natureza IN ('liquidacao_nota', 'provento', 'aporte', 'resgate', 'transferencia_saida', " \
        "'transferencia_entrada', 'cambio_saida', 'cambio_entrada', 'saldo_inicial')",
      name: "lancamentos_natureza_valida"
  end
end
