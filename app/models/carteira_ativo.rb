class CarteiraAtivo < ApplicationRecord
  has_many :operacoes
  belongs_to :corretora
  belongs_to :ativo
  belongs_to :carteira

  validates :ativo_id, uniqueness: { scope: [ :carteira_id, :corretora_id ] }

  #before_save :abort_se_tem_na_carteira, if: :valido_changed?

  def data_montagem
    Rails.cache.fetch("data_montagem_ca_id#{id}", expires_in: 5.seconds) do
      operacoes.where(mon_ou_des: 1).order(data: :desc).limit(1)[0].data
    end
  end

  # Utilizado em formulários
  def nome_amigavel
    "#{ativo.nome_amigavel} - #{corretora.nome}"
  end


  # Calcula preço médio de compra
  def preco_medio(data_fim, moeda: 'BRL')
    Rails.cache.fetch("preco_medio_ca_id#{id}", expires_in: 5.seconds) do
      data_fim_str = data_fim.strftime '%F'
      data_montagem_str = data_montagem.strftime '%F'

      if ativo.moeda == 'USD' && moeda == 'BRL'
        sum_str = 'quantidade * valor_unit * usdbrl'
      else # não temos valor de BRL para USD
        sum_str = 'quantidade * valor_unit'
      end

      sql = <<~SQL
          select sum(#{sum_str})/sum(quantidade) as preco_medio
          from operacoes
          where carteira_ativo_id = #{id} and 
           operacao = 1 and 
           data >= '#{data_montagem_str}' and
           data <= '#{data_fim_str}'
      SQL

      ActiveRecord::Base.connection.execute(sql).values[0][0]
    end
  end

  # Última cotação do Ativo
  #
  # @return Cotacao object
  def cotacao
    Cotacao.cotacao_ativo(ativo.id)
  end

  def quantidade
    Rails.cache.fetch("quantidade_ca_#{id}", expires_in: 5.seconds) do
      operacoes.sum(:quantidade)
    end
  end

  def valor_investido(moeda: 'BRL')
    if moeda == 'BRL'
      operacoes.sum('valor_unit * quantidade * usdbrl')
    else # USD
      # FIXME:
      # não temos a cotacao brlusd armazenada a época para definir
      # qual a cotação usar
      operacoes.sum('valor_unit * quantidade')
    end
  end

  def valor_posicao(moeda: 'BRL')
    cotacao ? cotacao.valor_unit_moeda(moeda: moeda) * quantidade.to_f : 0
  end

  def rentabilidade(data_fim = Date.today)
    cotacao ? ((cotacao.valor_unit_moeda / preco_medio(data_fim)) - 1) * 100 : 0
  end


  private

  # # Aborta operação de save se houver tentativa de desabilitar
  # # a carteira_ativo (valido = false) quanto ele ainda esta presente na carteira
  # # ou seja, sua quantidade diferente de 0
  # def abort_se_tem_na_carteira
  #   new_value = valido_change_to_be_saved[1]
  #   throw(:abort) if (new_value == false) && (quantidade != 0)
  # end

end
