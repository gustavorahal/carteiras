class Operacao < ApplicationRecord
  attr_accessor :valor

  belongs_to :corretora
  belongs_to :ativo
  belongs_to :carteira

  before_save :ajusta_quantidade, :ajusta_dolar, :ajusta_mon_ou_des
  after_save :insere_extrato_entrada_tmp

  enum :operacao, {
    C: 1,
    V: 2,
    IR: 3,
    S: 4
  }

  enum :mon_ou_des, {
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
    (valor_unit.present? && quantidade.present?) ? (valor_unit * quantidade) : nil
  end

  # Saldo financeiro da operação
  #
  # Em uma operácão de venda, temos um valor negativo na operação, entretanto o saldo financeiro é positivo, afinal,
  # entrou dinheiro. Isso se aplica inversamente ao caso de compra. Na compra gastamos, portanto o saldo
  # financeiro é negativo.
  def saldo_financeiro
    valor * -1
  end

  private

    def ajusta_quantidade
      if (V? && quantidade.positive?) ||
         (S? && quantidade.positive?) ||
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

      if C? && quant_total.negative? && quant_total == (quantidade * -1)
        # se estamos comprando uma quantidade equivalente ao que
        # temos de negativo, e porque estamos desmontando uma operacao de short
        self.mon_ou_des = 'D'
      elsif (C? || S?) && quant_total.zero?
        # se estamos vendendo ou fazendo um short, e nao temos nada do ativo
        # estamos certamente montando uma posicao
        self.mon_ou_des = 'M'
      elsif V? && quant_total == (quantidade * -1)
        # se estamos vendendo uma quantidade equivalente ao que
        # temos, e porque estamos desmontando uma operacao
        self.mon_ou_des = 'D'
      end

    end

    def insere_extrato_entrada_tmp
      cc = ContaCorrente.find_by(corretora_id: corretora.id, carteira_id: carteira.id,
                                 moeda: ativo.moeda_negociacao)
      # Só faz sentido adicionar uma entrada temporária, se a operação é posterior
      # a ultima entrada "real" (não temporária) do extrato para dada CC.
      return if data <= cc.extratos.where(temporario: false).last.movimentacao

      # a descrição é pobre propositalmente para podermos encontra-la em caso de edições
      # subsequentes da operação e assim deleta-la para criação de outra entrada
      descricao = "Operação ID##{id}"

      # Entrada já adicionada? Por exemplo, estamos editando uma operação. Deletar para adicionar outra
      Extrato.where(descricao: descricao, temporario: true).delete_all

      Extrato.create!(conta_corrente: cc,
                      liquidacao: data,
                      movimentacao: data,
                      valor: saldo_financeiro,
                      descricao: descricao,
                      temporario: true)
    end

end
