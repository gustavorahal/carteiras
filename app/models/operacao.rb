class Operacao < ApplicationRecord
  belongs_to :corretora
  belongs_to :ativo
  belongs_to :carteira

  validates_presence_of :valor_unit
  validates_presence_of :quantidade

  before_save :ajusta_quantidade, :ajusta_dolar, :ajusta_mon_ou_des

  enum operacao: {
    C: 1,
    V: 2,
    IR: 3,
    S: 4
  }

  enum mon_ou_des: {
    M: 1,
    D: 2
  }

  def custos_operacionais
    (co_taxa || 0) + (co_emolumentos || 0) + (co_corretagem || 0) + (co_iss_iof || 0) + (co_irrf || 0) + (co_outros || 0)
  end

  def self.quantidade_total(carteira, ativo, data)
    Operacao.where(carteira: carteira, ativo: ativo).where('data <= ?', data).sum(:quantidade)
  end


  private


  def ajusta_quantidade
    if (V? && quantidade.positive?) ||
       (C? && quantidade.negative?)
      self.quantidade *= -1
    end
  end

  def ajusta_dolar
    self.usdbrl = if ativo.usd? && usdbrl == 1
                    CotacaoService.cotacao_usdbrl(data).valor_unit
                  elsif ativo.brl?
                    1
                  else
                    usdbrl
                  end
    Rails.logger.info "Operacao Model ajustou dolar para #{self.usdbrl}"
  end

  def ajusta_mon_ou_des
    quant_total = self.class.quantidade_total(carteira, ativo, data)

    if C? && quant_total.zero?
      self.mon_ou_des = 'M'
    elsif V? && quant_total == (quantidade * -1)
      self.mon_ou_des = 'D'
    end

  end

end
