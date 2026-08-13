class TransacoesFinanceirasController < ApplicationController
  rescue_from Financeiro::AtributosInvalidos, Financeiro::HistoricoInvalido, Financeiro::RegistroArquivado,
    with: :renderizar_erro_corrigivel
  rescue_from Financeiro::EstadoInvalido, Financeiro::ConflitoIdempotencia, with: :renderizar_conflito
  before_action :carregar_espaco
  before_action :carregar_transacao, only: %i[show edit update destroy confirmar reverter corrigir correcao]
  before_action :carregar_opcoes, only: %i[show new create edit update corrigir correcao prever]

  def index
    @carteiras = Carteira.joins(:investidor).where(investidores: { espaco_id: @espaco.id }).order(:nome)
    inicio = Date.iso8601(params[:inicio]) if params[:inicio].present?
    fim = Date.iso8601(params[:fim]) if params[:fim].present?
    @transacoes = TransacaoFinanceira.joins(:investidor).where(investidores: { espaco_id: @espaco.id }).includes(:investidor)
      .then { |q| params[:investidor_id].present? ? q.where(investidor_id: params[:investidor_id]) : q }
      .then { |q| filtrar_por_carteira(q, params[:carteira_id]) }
      .then { |q| params[:tipo].present? ? q.where(tipo: params[:tipo]) : q }
      .then { |q| params[:estado].present? ? q.where(estado: params[:estado]) : q }
      .then { |q| inicio ? q.where(data_competencia: inicio..) : q }
      .then { |q| fim ? q.where(data_competencia: ..fim) : q }
      .order(data_competencia: :desc, ordem_na_data: :desc, id: :desc)
  rescue Date::Error
    flash.now[:alert] = "Período inválido."
    @transacoes = TransacaoFinanceira.none
    render :index, status: :unprocessable_content
  end

  def show
    authorize @transacao
    if @transacao.rascunho? && policy(@transacao).update?
      @tipo = @transacao.tipo
      @investidor = @transacao.investidor
      @previa = TransacoesFinanceiras.prever(tipo: @tipo, investidor: @investidor,
        usuario: current_user, atributos: atributos_da_transacao(@transacao))
    end
  end

  def new
    @tipo = params[:tipo].presence_in(TransacaoFinanceira::TIPOS - ["reversao"]) || "movimentacao_caixa"
    @investidor = @espaco.investidores.ativos.find_by(id: params[:investidor_id]) || @espaco.investidores.ativos.first
    raise ActiveRecord::RecordNotFound unless @investidor
    authorize @investidor.transacoes_financeiras.new, :create?
  end

  def prever
    if params[:id].present?
      @transacao = TransacaoFinanceira.joins(:investidor).where(investidores: { espaco_id: @espaco.id }).find(params[:id])
      @correcao = params[:correcao] == "1"
      authorize @transacao, @correcao ? :corrigir? : :update?
      @tipo = @transacao.tipo
      @investidor = @transacao.investidor
    else
      @tipo = params[:tipo]
      @investidor = @espaco.investidores.find(params[:investidor_id])
    end
    @atributos_formulario = params.require(:atributos).to_unsafe_h.deep_symbolize_keys
    @movimento = @atributos_formulario[:tipo_movimentacao]
    @previa = TransacoesFinanceiras.prever(tipo: @tipo, investidor: @investidor,
      usuario: current_user, atributos: atributos_traduzidos,
      transacao_original: @correcao ? @transacao : nil)
    render(@correcao ? :correcao : (@transacao ? :edit : :new))
  end

  def create
    @tipo = params[:tipo]
    @investidor = @espaco.investidores.find(params[:investidor_id])
    @transacao = TransacoesFinanceiras.criar_rascunho(tipo: @tipo, investidor: @investidor,
      usuario: current_user, atributos: atributos_traduzidos, chave_idempotencia: params[:chave_idempotencia])
    redirect_to espaco_transacao_path(@espaco, @transacao), notice: "Rascunho criado."
  end

  def edit
    authorize @transacao
    @tipo = @transacao.tipo
    @investidor = @transacao.investidor
    @atributos_formulario = atributos_da_transacao(@transacao)
    @movimento = @atributos_formulario[:tipo_movimentacao]
  end

  def correcao
    authorize @transacao, :corrigir?
    @tipo = @transacao.tipo
    @investidor = @transacao.investidor
    @atributos_formulario = atributos_da_transacao(@transacao)
    @movimento = @atributos_formulario[:tipo_movimentacao]
    @correcao = true
  end

  def update
    authorize @transacao
    TransacoesFinanceiras.atualizar_rascunho(transacao: @transacao, usuario: current_user, atributos: atributos_traduzidos)
    redirect_to espaco_transacao_path(@espaco, @transacao), notice: "Rascunho atualizado."
  end

  def destroy
    authorize @transacao
    TransacoesFinanceiras.excluir_rascunho(transacao: @transacao, usuario: current_user)
    redirect_to espaco_transacoes_path(@espaco), notice: "Rascunho excluído."
  end

  def confirmar
    authorize @transacao, :confirmar?
    TransacoesFinanceiras.confirmar(transacao: @transacao, usuario: current_user)
    redirect_to espaco_transacao_path(@espaco, @transacao), notice: "Transação confirmada."
  end

  def reverter
    authorize @transacao, :reverter?
    reversao = TransacoesFinanceiras.reverter(transacao: @transacao, usuario: current_user)
    redirect_to espaco_transacao_path(@espaco, reversao), notice: "Transação revertida."
  end

  def corrigir
    authorize @transacao, :corrigir?
    resultado = TransacoesFinanceiras.corrigir(transacao: @transacao, usuario: current_user, atributos: atributos_traduzidos)
    redirect_to espaco_transacao_path(@espaco, resultado.substituta), notice: "Correção aplicada atomicamente."
  end

  private

  def carregar_transacao
    @transacao = TransacaoFinanceira.joins(:investidor).where(investidores: { espaco_id: @espaco.id }).find(params[:id])
  end

  def carregar_opcoes
    @investidores = @espaco.investidores.ativos.order(:nome)
    @caixas = ContaCaixa.ativos.joins(conta_investimento: { carteira: :investidor })
      .where(investidores: { espaco_id: @espaco.id }).includes(:moeda, conta_investimento: :carteira)
    @ativos = Ativo.ativos.order(:codigo)
    @contas_investimento = ContaInvestimento.ativos.joins(carteira: :investidor)
      .where(investidores: { espaco_id: @espaco.id }).includes(:carteira).order(:nome)
  end

  def filtrar_por_carteira(relacao, carteira_id)
    return relacao if carteira_id.blank?

    carteira = Carteira.joins(:investidor).where(investidores: { espaco_id: @espaco.id }).find(carteira_id)
    caixas = ContaCaixa.joins(:conta_investimento).where(contas_investimento: { carteira_id: carteira.id }).select(:id)
    por_nota = relacao.where(id: NotaNegociacao.where(conta_caixa_id: caixas).select(:transacao_financeira_id))
    por_provento = relacao.where(id: Provento.where(conta_caixa_id: caixas).select(:transacao_financeira_id))
    movimentos = MovimentacaoCaixa.where(conta_caixa_origem_id: caixas)
      .or(MovimentacaoCaixa.where(conta_caixa_destino_id: caixas)).select(:transacao_financeira_id)
    contas = carteira.contas_investimento.select(:id)
    saldos = SaldoInicial.where(conta_investimento_id: contas).select(:transacao_financeira_id)
    custodias = TransferenciaCustodia.where(conta_origem_id: contas)
      .or(TransferenciaCustodia.where(conta_destino_id: contas)).select(:transacao_financeira_id)
    eventos = EventoCorporativo.where(conta_investimento_id: contas).select(:transacao_financeira_id)
    originais = por_nota.or(por_provento).or(relacao.where(id: movimentos)).or(relacao.where(id: saldos))
      .or(relacao.where(id: custodias)).or(relacao.where(id: eventos))
    originais.or(relacao.where(transacao_revertida_id: originais.select(:id)))
  end

  def atributos_traduzidos
    hash = params.require(:atributos).to_unsafe_h.deep_symbolize_keys
    traduzir_ids!(hash)
    Array(hash[:negociacoes]).each { |linha| linha.delete(:custo_alocado) if linha[:custo_alocado].blank? }
    hash
  end

  def atributos_da_transacao(transacao)
    comum = { observacao: transacao.observacao, ordem_na_data: transacao.ordem_na_data }
    case transacao.tipo
    when "nota_negociacao"
      nota = transacao.nota_negociacao
      comum.merge(conta_caixa_id: nota.conta_caixa_id, data_negociacao: nota.data_negociacao,
        data_liquidacao: nota.data_liquidacao, custo_operacional_total: nota.custo_operacional_total.to_s("F"),
        taxa_conversao_base: nota.taxa_conversao_base.to_s("F"),
        negociacoes: nota.negociacoes.order(:ordem).map { |n| { ativo_id: n.ativo_id, natureza: n.natureza,
          quantidade: n.quantidade.to_s("F"), preco_unitario: n.preco_unitario.to_s("F"),
          custo_alocado: n.custo_alocado.to_s("F") } })
    when "provento"
      provento = transacao.provento
      comum.merge(conta_caixa_id: provento.conta_caixa_id, ativo_id: provento.ativo_id,
        tipo_provento: provento.tipo, data_base: provento.data_base, data_pagamento: provento.data_pagamento,
        quantidade_referencia: provento.quantidade_referencia.to_s("F"), valor_bruto: provento.valor_bruto.to_s("F"),
        retencoes: provento.retencoes.to_s("F"), taxa_conversao_base: provento.taxa_conversao_base.to_s("F"))
    when "movimentacao_caixa"
      movimento = transacao.movimentacao_caixa
      dados = comum.merge(tipo_movimentacao: movimento.tipo, conta_caixa_origem_id: movimento.conta_caixa_origem_id,
        conta_caixa_destino_id: movimento.conta_caixa_destino_id, data_efetiva: movimento.data_efetiva)
      if movimento.tipo == "cambio"
        dados.merge(valor_origem: movimento.valor_origem.to_s("F"), valor_destino: movimento.valor_destino.to_s("F"))
      else
        dados.merge(valor: (movimento.valor_origem || movimento.valor_destino).to_s("F"))
      end
    when "saldo_inicial"
      saldo = transacao.saldo_inicial
      dados = comum.merge(conta_investimento_id: saldo.conta_investimento_id, ativo_id: saldo.ativo_id,
        quantidade: saldo.quantidade.to_s("F"), fonte_custo: saldo.fonte_custo,
        data_efetiva: transacao.data_competencia)
      if saldo.preco_medio_local_informado
        dados.merge(preco_medio_local: saldo.preco_medio_local_informado.to_s("F"),
          preco_medio_base: saldo.preco_medio_base_informado.to_s("F"))
      else
        dados.merge(custo_total_local: saldo.custo_total_local.to_s("F"),
          custo_total_base: saldo.custo_total_base.to_s("F"))
      end
    when "transferencia_custodia"
      transferencia = transacao.transferencia_custodia
      comum.merge(conta_origem_id: transferencia.conta_origem_id, conta_destino_id: transferencia.conta_destino_id,
        ativo_id: transferencia.ativo_id, quantidade: transferencia.quantidade.to_s("F"),
        data_efetiva: transacao.data_competencia)
    when "evento_corporativo"
      evento = transacao.evento_corporativo
      comum.merge(tipo_evento: evento.tipo, conta_investimento_id: evento.conta_investimento_id,
        ativo_origem_id: evento.ativo_origem_id, ativo_destino_id: evento.ativo_destino_id,
        quantidade_final: evento.quantidade_final.to_s("F"), data_efetiva: transacao.data_competencia)
    end
  end

  def traduzir_ids!(objeto)
    case objeto
    when Hash
      objeto.each do |chave, valor|
        objeto[chave] = if (chave == :ordem_na_data || chave.to_s.end_with?("_id")) && valor.blank?
          nil
        elsif chave.to_s.end_with?("_id") && valor.present?
          Integer(valor, 10)
        elsif chave == :ordem_na_data && valor.present?
          Integer(valor, 10)
        else
          traduzir_ids!(valor)
        end
      end
    when Array then objeto.each { |item| traduzir_ids!(item) }
    end
    objeto
  rescue ArgumentError
    raise Financeiro::AtributosInvalidos.new(ids: ["devem ser inteiros"])
  end

  def renderizar_erro_corrigivel(erro)
    flash.now[:alert] = erro.detalhes.values.flatten.join(", ")
    @tipo ||= @transacao&.tipo || params[:tipo]
    @investidor ||= @transacao&.investidor || @espaco.investidores.find_by(id: params[:investidor_id])
    @atributos_formulario = params[:atributos]&.to_unsafe_h&.deep_symbolize_keys || {}
    @movimento = @atributos_formulario[:tipo_movimentacao]
    template = case action_name
    when "create" then :new
    when "prever" then @correcao ? :correcao : (@transacao ? :edit : :new)
    when "corrigir" then @correcao = true; :correcao
    when "update" then :edit
    else :show
    end
    render template, status: :unprocessable_content
  end

  def renderizar_conflito(erro)
    flash.now[:alert] = "O estado mudou: #{erro.detalhes.values.flatten.join(', ')}"
    if @transacao
      @transacao.reload
      render :show, status: :conflict
    else
      @tipo ||= params[:tipo]
      @investidor ||= @espaco.investidores.find_by(id: params[:investidor_id])
      @atributos_formulario = params[:atributos]&.to_unsafe_h&.deep_symbolize_keys || {}
      render :new, status: :conflict
    end
  end
end
