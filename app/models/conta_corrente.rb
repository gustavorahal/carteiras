class ContaCorrente < ApplicationRecord
  has_many :extratos
  belongs_to :corretora
  belongs_to :carteira

  validates :carteira_id, uniqueness: { scope: [ :moeda, :corretora_id ] }

  def saldo(data)
    extratos.where("movimentacao <= '#{data}'::date").sum(:valor).round(4)
  end

  def extratos_data(data)
    extratos.where("movimentacao::date <= '#{data}'").order(movimentacao: :desc, created_at: :desc)
  end

  def self.saldo_cc_brl(carteira, data, corretora = nil)
    query = Extrato.joins(:conta_corrente)
           .where('conta_correntes.carteira_id': carteira.id)
           .where('conta_correntes.moeda': 'BRL')
           .where("movimentacao::date <= '#{data}'")
    if corretora
      query = query.where('conta_correntes.corretora_id': corretora.id)
    end

    query.sum(:valor)
  end

  def self.saldo_cc_usd(carteira, data, corretora = nil)
    query = Extrato.joins(:conta_corrente)
           .where('conta_correntes.carteira_id': carteira.id)
           .where('conta_correntes.moeda': 'USD')
           .where("movimentacao::date <= '#{data}'")
    if corretora
      query = query.where('conta_correntes.corretora_id': corretora.id)
    end

    query.sum(:valor)
  end

  def self.saldo_cc_total(carteira, data, corretora = nil)
    total_brl = saldo_cc_brl(carteira, data, corretora)
    total_usd = saldo_cc_usd(carteira, data, corretora)
    total_usdbrl = total_usd * CotacaoService.moedas('USDBRL', data).valor_unit

    total_brl + total_usdbrl
  end

end
