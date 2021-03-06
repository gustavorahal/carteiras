class ContaCorrente < ApplicationRecord
  has_many :extratos
  belongs_to :corretora
  belongs_to :investidor

  validates :investidor_id, uniqueness: { scope: [ :moeda, :corretora_id ] }

  def saldo(data)
    extratos.where("liquidacao <= '#{data}'::date").sum(:valor)
  end

  def self.saldo_cc_brl(investidor, data)
    Extrato.joins(:conta_corrente)
           .where('conta_correntes.investidor_id': investidor.id)
           .where('conta_correntes.moeda': 'BRL')
           .where("liquidacao::date <= '#{data}'")
           .sum(:valor)
  end
    
  def self.saldo_cc_usd(investidor, data)
    Extrato.joins(:conta_corrente)
           .where('conta_correntes.investidor_id': investidor.id)
           .where('conta_correntes.moeda': 'USD')
           .where("liquidacao::date <= '#{data}'")
           .sum(:valor)
  end
  
  def self.saldo_cc_total(investidor, data)
    total_brl = saldo_cc_brl(investidor, data)
    total_usd = saldo_cc_usd(investidor, data)
    total_usdbrl = total_usd * CotacaoService.cotacao_usdbrl(data).valor_unit

    total_brl + total_usdbrl
  end

end
