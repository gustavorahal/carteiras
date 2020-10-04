class ContaCorrente < ApplicationRecord
  has_many :extratos
  belongs_to :corretora
  belongs_to :investidor

  validates :investidor_id, uniqueness: { scope: [ :moeda, :corretora_id ] }

  def saldo(data)
    extratos.where("liquidacao <= '#{data}'::date").sum(:valor)
  end

  def self.saldo_cc_total(investidor, data)
    total_brl = Extrato.joins(:conta_corrente)
                    .where('conta_correntes.investidor_id': investidor.id)
                    .where('conta_correntes.moeda': 'BRL')
                    .where("liquidacao <= '#{data}'::date")
                    .sum(:valor)
    total_usd = Extrato.joins(:conta_corrente)
                    .where('conta_correntes.investidor_id': investidor.id)
                    .where('conta_correntes.moeda': 'USD')
                    .where("liquidacao <= '#{data}'::date")
                    .sum(:valor)
    total_usdbrl = total_usd * Cotacao.cotacao_usdbrl(data: data).valor_unit

    total_brl + total_usdbrl
  end

end
