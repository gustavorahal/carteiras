class Carteira < ApplicationRecord
  include Arquivavel
  include Normalizavel

  belongs_to :investidor, inverse_of: :carteiras
  belongs_to :moeda_base, class_name: "Moeda", inverse_of: :carteiras_base
  has_many :contas_investimento, class_name: "ContaInvestimento", inverse_of: :carteira
  has_many :contas_caixa, class_name: "ContaCaixa", through: :contas_investimento
  has_many :classificacoes_ativos, class_name: "ClassificacaoAtivoCarteira", inverse_of: :carteira

  delegate :espaco, to: :investidor
  normaliza_texto :nome
  validates :nome, presence: true, uniqueness: { scope: :investidor_id, case_sensitive: false }
  validate :ascendencia_disponivel, on: :create
  validate :moeda_base_imutavel_apos_fato, on: :update

  def possui_fato_confirmado?
    TransacaoFinanceira.confirmadas.joins(nota_negociacao: { conta_caixa: :conta_investimento })
      .where(contas_investimento: { carteira_id: id }).exists? ||
      TransacaoFinanceira.confirmadas.joins(provento: { conta_caixa: :conta_investimento })
        .where(contas_investimento: { carteira_id: id }).exists? ||
      TransacaoFinanceira.confirmadas.joins(movimentacao_caixa: [conta_caixa_origem: :conta_investimento])
        .where(contas_investimento: { carteira_id: id }).exists? ||
      TransacaoFinanceira.confirmadas.joins(movimentacao_caixa: [conta_caixa_destino: :conta_investimento])
        .where(contas_investimento: { carteira_id: id }).exists? ||
      TransacaoFinanceira.confirmadas.joins(:saldo_inicial)
        .where(saldos_iniciais: { conta_investimento_id: contas_investimento.select(:id) }).exists? ||
      TransacaoFinanceira.confirmadas.joins(saldo_inicial_caixa: { conta_caixa: :conta_investimento })
        .where(contas_investimento: { carteira_id: id }).exists? ||
      TransacaoFinanceira.confirmadas.joins(:transferencia_custodia)
        .where("transferencias_custodia.conta_origem_id IN (:ids) OR transferencias_custodia.conta_destino_id IN (:ids)",
          ids: contas_investimento.select(:id)).exists? ||
      TransacaoFinanceira.confirmadas.joins(:evento_corporativo)
        .where(eventos_corporativos: { conta_investimento_id: contas_investimento.select(:id) }).exists?
  end

  private

  def ascendencia_disponivel
    errors.add(:investidor, "está arquivado") if investidor&.arquivado? || investidor&.espaco&.arquivado?
    errors.add(:moeda_base, "está arquivada") if moeda_base&.arquivado?
  end

  def moeda_base_imutavel_apos_fato
    errors.add(:moeda_base, "não pode mudar após o primeiro fato confirmado") if will_save_change_to_moeda_base_id? && possui_fato_confirmado?
  end
end
