class Operacao < ApplicationRecord
  belongs_to :carteira_ativo

  enum operacao: {
      compra: 1,
      venda: 2,
      resgate_ir: 3
  }

  enum mon_ou_des: {
      montagem: 1,
      desmontagem: 2
  }

  def self.data_montagem(carteira_ativo_id)
    where(carteira_ativo_id: carteira_ativo_id, mon_ou_des: 1)
        .order(data: :desc).limit(1)[0].data
  end

  # Calcula preço médio de compra
  def self.preco_medio(carteira_ativo_id, data_montagem, data_fim)
    sql = <<~SQL
        select sum(quantidade * valor_unit * usdbrl)/sum(quantidade) as preco_compra
        from operacoes
        where carteira_ativo_id = #{carteira_ativo_id} and 
         operacao = 1 and 
         data >= '#{data_montagem}' and
         data <= '#{data_fim}'
    SQL

    ActiveRecord::Base.connection.execute(sql).values[0][0]
  end

end
