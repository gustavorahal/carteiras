#
# https://www.planejar.org.br/investimentos/como-e-a-tributacao-dos-fundos-imobiliarios/
#
# Observações relevantes sobre impostos
#
# 1. As vendas de cotas de FII não são isentas, qualquer que seja o valor das vendas,
# isto é, o IR deve ser sempre apurado e, se for o caso, recolhido.
# 2. Só é admitida compensação de prejuízos com ganhos posteriores entre **ativos da mesma espécie**,
# isto é, **perdas com ações não podem ser compensadas com ganhos em cotas de FII** – e vice-versa.

class Impostos

  # @param tipo: Um dos tipos de ativos definidos em Ativo
  def self.tributacao_mes_a_mes(carteira, ano, tipo)
    mes_atual = Date.today.month
    sumario = {}
    imposto_a_pagar_acumulado = 0
    (1..mes_atual).to_a.each do |mes|
      lucro_liquido_mes = 0
      imposto_a_pagar_mes = 0
      valor_venda_mes = 0
      imposto_operacoes = imposto_operacoes_no_mes(carteira, ano, mes, tipo)
      next if imposto_operacoes.empty?

      imposto_operacoes.each do |imposto_operacao|
        lucro_liquido_mes += imposto_operacao.lucro_liquido
        imposto_a_pagar_mes += imposto_operacao.imposto_a_pagar
        valor_venda_mes += imposto_operacao.valor_venda
      end
      imposto_a_pagar_acumulado += imposto_a_pagar_mes
      sumario[mes] = { imposto_operacoes: imposto_operacoes,
                       lucro_liquido: lucro_liquido_mes,
                       imposto_a_pagar: imposto_a_pagar_mes,
                       valor_venda: valor_venda_mes,
                       imposto_a_pagar_acumulado: imposto_a_pagar_acumulado }
    end

    sumario
  end

  #
  # Private
  #


  # Operações tributáveis em dado mês
  #
  # @return Operações que podem ser tributavéis
  def self.operacoes_tributaveis_no_mes(carteira, ano, mes, tipos = [:acao, :fii])
    comeco_mes = Date.new(ano, mes).beginning_of_month
    fim_mes = Date.new(ano, mes).end_of_month
    Operacao.operacoes_carteira(carteira.id)
        .where(data: comeco_mes..fim_mes,
               operacao: 'V',
               'ativos.tipo': (tipos.map { |tipo| Ativo.tipos[tipo] }))
  end

  def self.imposto_operacoes_no_mes(carteira, ano, mes, tipo)
    impst_opr_mes = []
    operacoes_tributaveis_no_mes(carteira, ano, mes, [tipo]).each do |operacao|
      impst_opr_mes.push ImpostoOperacao.new(operacao)
    end

    impst_opr_mes
  end

end



class ImpostoOperacao

  attr_reader :ativo

  def initialize(operacao)
    @operacao = operacao
    @carteira_ativo = operacao.carteira_ativo
    @ativo = operacao.carteira_ativo.ativo

    raise StandardError, "Operação ID #{operacao.id} não tributável" if operacao.operacao != 'V' || !@ativo.tipo.in?(%w[acao fii])

    @cap = CarteiraAtivoPosicao.new(@carteira_ativo, operacao.data)
    @data_inicio = @cap.data_montagem
    @data_fim = operacao.data

  end

  def custos_operacionais
    Operacao
      .where(carteira_ativo_id: @carteira_ativo.id)
      .where(data: @data_inicio..@data_fim)
      .sum('(co_taxa + co_emolumentos + co_corretagem + co_iss_iof + co_irrf + co_outros) * usdbrl')
  end

  def quantidade_vendida
    @operacao.quantidade.negative? ? @operacao.quantidade * -1 : @operacao.quantidade
  end

  def data_montagem
    @cap.data_montagem
  end

  def preco_medio_compra
    @cap.preco_medio_em_brl
  end

  def valor_venda
    @operacao.valor_total_brl
  end

  def preco_venda
    @operacao.valor_unit * @operacao.usdbrl
  end

  def lucro_bruto
    valor_venda - (preco_medio_compra * quantidade_vendida)
  end

  def lucro_liquido
    lucro_bruto - custos_operacionais
  end

  def imposto_a_pagar
    lucro_liquido * percent_imposto
  end

  def percent_imposto
    if @ativo.tipo == 'acao'
      0.15
    elsif @ativo.tipo == 'fii' && @ativo.moeda == 'USD' # no exterior é sempre 15%
      0.15
    elsif @ativo.tipo == 'fii' && @ativo.moeda == 'BRL'
      0.20
    else
      raise StandardError, "Não é possível determinar % do imposto para ativo #{@ativo.nome} tipo #{@ativo.tipo}"
    end
  end

end