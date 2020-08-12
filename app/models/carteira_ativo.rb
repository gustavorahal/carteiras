class CarteiraAtivo < ApplicationRecord
  has_many :operacoes
  belongs_to :ativo
  belongs_to :carteira

  def data_montagem
    operacoes.where(mon_ou_des: 1).order(data: :desc).limit(1)[0].data
  end

  # Utilizado em formulários
  def nome_amigavel
    ativo.nome_amigavel
  end


  # Calcula preço médio de compra
  def preco_medio(data_fim)
    data_fim_str = data_fim.strftime '%F'
    data_montagem_str = data_montagem.strftime '%F'

    sql = <<~SQL
        select sum(quantidade * valor_unit * usdbrl)/sum(quantidade) as preco_compra
        from operacoes
        where carteira_ativo_id = #{id} and 
         operacao = 1 and 
         data >= '#{data_montagem_str}' and
         data <= '#{data_fim_str}'
    SQL

    ActiveRecord::Base.connection.execute(sql).values[0][0]
  end

  # Última cotação do Ativo
  #
  # @return Cotacao object
  def ultima_cotacao
    Cotacao.ultima_cotacao(ativo.id)
  end


end
