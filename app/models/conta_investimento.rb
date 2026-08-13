class ContaInvestimento < ApplicationRecord
  self.table_name = "contas_investimento"
  include Arquivavel
  include Normalizavel

  belongs_to :carteira, inverse_of: :contas_investimento
  belongs_to :instituicao, inverse_of: :contas_investimento
  has_many :contas_caixa, class_name: "ContaCaixa", inverse_of: :conta_investimento
  has_many :moedas, through: :contas_caixa
  has_many :posicoes_atuais, class_name: "PosicaoAtual", inverse_of: :conta_investimento
  has_many :importacoes_financeiras, class_name: "ImportacaoFinanceira", inverse_of: :conta_investimento
  has_many :saldos_iniciais, class_name: "SaldoInicial", inverse_of: :conta_investimento
  has_many :transferencias_custodia_origem, class_name: "TransferenciaCustodia", foreign_key: :conta_origem_id,
    inverse_of: :conta_origem
  has_many :transferencias_custodia_destino, class_name: "TransferenciaCustodia", foreign_key: :conta_destino_id,
    inverse_of: :conta_destino
  has_many :eventos_corporativos, class_name: "EventoCorporativo", inverse_of: :conta_investimento

  delegate :investidor, :espaco, to: :carteira
  normaliza_texto :nome, :identificador_externo
  validates :nome, presence: true, uniqueness: { scope: :carteira_id, case_sensitive: false }
  validate :ascendencia_disponivel, on: :create
  validate :carteira_imutavel_apos_fato, on: :update

  def possui_fato_confirmado?
    caixas = contas_caixa.select(:id)
    TransacaoFinanceira.confirmadas.joins(:nota_negociacao)
      .where(notas_negociacao: { conta_caixa_id: caixas }).exists? ||
      TransacaoFinanceira.confirmadas.joins(:provento)
        .where(proventos: { conta_caixa_id: caixas }).exists? ||
      TransacaoFinanceira.confirmadas.joins(:movimentacao_caixa)
        .where("movimentacoes_caixa.conta_caixa_origem_id IN (?) OR movimentacoes_caixa.conta_caixa_destino_id IN (?)", caixas, caixas).exists? ||
      TransacaoFinanceira.confirmadas.joins(:saldo_inicial).where(saldos_iniciais: { conta_investimento_id: id }).exists? ||
      TransacaoFinanceira.confirmadas.joins(:transferencia_custodia)
        .where("transferencias_custodia.conta_origem_id = :id OR transferencias_custodia.conta_destino_id = :id", id:).exists? ||
      TransacaoFinanceira.confirmadas.joins(:evento_corporativo).where(eventos_corporativos: { conta_investimento_id: id }).exists?
  end

  private

  def ascendencia_disponivel
    errors.add(:carteira, "está arquivada") if carteira&.arquivado? || carteira&.investidor&.arquivado? || carteira&.espaco&.arquivado?
    errors.add(:instituicao, "está arquivada") if instituicao&.arquivado?
  end

  def carteira_imutavel_apos_fato
    errors.add(:carteira, "não pode mudar após o primeiro fato confirmado") if will_save_change_to_carteira_id? && possui_fato_confirmado?
  end
end
