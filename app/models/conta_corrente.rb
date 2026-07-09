class ContaCorrente < ApplicationRecord
  has_many :extratos
  belongs_to :corretora
  belongs_to :carteira

  validates :carteira_id, uniqueness: { scope: [ :moeda, :corretora_id ] }

  def nome
    "#{corretora.nome} (#{moeda})"
  end

  def saldo(data)
    extratos.where('movimentacao <= ?', data).sum(:valor).round(4)
  end

  def extratos_data(data)
    extratos.where('movimentacao <= ?', data).order(movimentacao: :desc)
  end

  def self.saldo_cc_brl(carteira, data, corretora = nil)
    query = Extrato.joins(:conta_corrente)
           .where('conta_correntes.carteira_id': carteira.id)
           .where('conta_correntes.moeda': 'BRL')
           .where('movimentacao <= ?', data)
    if corretora
      query = query.where('conta_correntes.corretora_id': corretora.id)
    end

    query.sum(:valor)
  end

  def self.saldo_cc_usd(carteira, data, corretora = nil)
    query = Extrato.joins(:conta_corrente)
           .where('conta_correntes.carteira_id': carteira.id)
           .where('conta_correntes.moeda': 'USD')
           .where('movimentacao <= ?', data)
    if corretora
      query = query.where('conta_correntes.corretora_id': corretora.id)
    end

    query.sum(:valor)
  end

  def self.saldo_cc_total(carteira, data, corretora = nil)
    total_brl = saldo_cc_brl(carteira, data, corretora)
    total_usd = saldo_cc_usd(carteira, data, corretora)
    return total_brl if total_usd.zero?

    cotacao_usdbrl = CotacaoService.moedas('USDBRL', data)
    raise StandardError, "Não foi possível obter cotação USDBRL para calcular saldo em USD" unless cotacao_usdbrl

    total_usdbrl = total_usd * cotacao_usdbrl.valor_unit

    total_brl + total_usdbrl
  end

end
