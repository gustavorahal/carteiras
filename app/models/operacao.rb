class Operacao < ApplicationRecord
  belongs_to :corretora
  belongs_to :ativo
  belongs_to :carteira

  validates_presence_of :valor_unit
  validates_presence_of :quantidade

  before_save :ajusta_quantidade, :ajusta_dolar, :ajusta_mon_ou_des
  after_save :insere_extrato

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

  def valor
    valor_unit * quantidade
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
                    CotacaoService.moedas('USDBRL', data).valor_unit
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

  def insere_extrato
    cc = ContaCorrente.find_by(corretora_id: corretora.id, carteira_id: carteira.id,
                               moeda: ativo.moeda)
    # Só faz sentido adicionar uma entrada temporária, se a operação é posterior
    # a ultima entrada "real" (não temporária) do extrato para dada CC.
    return if data <= cc.extratos.where(temporario: false).last.movimentacao

    # a descrição é pobre propositalmente para podermos encontra-la em caso de edições
    # subsequentes da operação e assim deleta-la para criação de outra entrada
    descricao = "Operação ID##{id}"

    # Entrada já adicionada? Por exemplo, estamos editando uma operação. Deletar para adicionar outra
    Extrato.where(descricao: descricao, temporario: true).delete_all

    # No caso de venda, temos um valor negativo na operação, entretanto no extrato seria uma entrada,
    # portanto positivo. Isso se aplica inversamente ao caso de compra.
    valor_corrigido = valor * -1

    Extrato.create!(conta_corrente: cc,
                    liquidacao: data,
                    movimentacao: data,
                    valor: valor_corrigido,
                    descricao: descricao,
                    temporario: true)
  end

end
