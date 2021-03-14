class AddOperacaoSysToOperacao < ActiveRecord::Migration[6.0]
  def change
    add_column :operacoes, :operacao_sys, :boolean, default: false
  end
end
