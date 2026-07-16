class ConciliarItemExtrato
  JANELA_DATAS = 3.days

  def self.call(item:, usuario:)
    new(item, usuario).call
  end

  def self.resolver(item:, usuario:, decisao:, lancamento: nil, classificacao: nil)
    new(item, usuario).resolver(decisao.to_s, lancamento, classificacao)
  end

  def initialize(item, usuario)
    @item = item
    @usuario = usuario
  end

  def call
    ItemExtratoImportado.transaction do
      @item.lock!
      return @item unless @item.pendente? || @item.ambiguo?
      candidatos = lancamentos_candidatos.to_a
      return vincular(candidatos.first) if candidatos.one?
      return marcar_ambiguo if candidatos.many?
      criar_evento_inequivoco || marcar_ambiguo
    end
  end

  def resolver(decisao, lancamento, classificacao)
    ItemExtratoImportado.transaction do
      @item.lock!
      case decisao
      when "vincular"
        raise ArgumentError, "Lançamento inválido para este item" unless lancamento_candidato?(lancamento)
        vincular(lancamento)
      when "criar_evento"
        @item.classificacao = classificacao
        criar_evento_inequivoco || raise(ArgumentError, "Classificação incompatível com o sinal do item")
      when "ignorar"
        @item.update!(evento_financeiro: nil, lancamento_caixa: nil,
          estado_conciliacao: :ignorado, decisao: "ignorado manualmente",
          usuario_responsavel: @usuario, decidido_em: Time.current)
      else
        raise ArgumentError, "Decisão de conciliação inválida"
      end
      @item
    end
  end

  private

  def lancamentos_candidatos
    usados = ItemExtratoImportado.where.not(lancamento_caixa_id: nil).select(:lancamento_caixa_id)
    escopo = LancamentoCaixa.where(conta_caixa: @item.importacao_extrato.conta_caixa, valor: @item.valor)
      .where(data_efetiva: (@item.data_liquidacao - JANELA_DATAS)..(@item.data_liquidacao + JANELA_DATAS))
      .where.not(id: usados)
    if @item.identificador_externo.present?
      conta = @item.importacao_extrato.conta_caixa
      chave = "extrato:#{conta.corretora_id}:#{@item.identificador_externo}"
      evento = conta.carteira.eventos_financeiros.find_by(chave_idempotencia: chave)
      return escopo.where(evento_financeiro: evento) if evento
    end
    escopo
  end

  def lancamento_candidato?(lancamento)
    lancamento && lancamentos_candidatos.where(id: lancamento.id).exists?
  end

  def vincular(lancamento)
    @item.update!(lancamento_caixa: lancamento, evento_financeiro: nil,
      estado_conciliacao: :conciliado, decisao: "lançamento esperado",
      usuario_responsavel: @usuario, decidido_em: Time.current)
    @item
  end

  def criar_evento_inequivoco
    natureza = @item.classificacao.presence || classificar_descricao
    return unless natureza.in?(%w[aporte resgate])
    direcao = @item.valor.positive? ? :entrada : :saida
    return if (natureza == "aporte") != (direcao == :entrada)

    conta = @item.importacao_extrato.conta_caixa
    chave = if @item.identificador_externo.present?
      "extrato:#{conta.corretora_id}:#{@item.identificador_externo}"
    else
      "item-extrato:#{@item.id}"
    end
    evento = RegistrarMovimentacaoCaixa.call(carteira: conta.carteira, usuario: @usuario,
      atributos: { conta_caixa: conta, natureza:, direcao:, valor: @item.valor.abs,
        data_efetiva: @item.data_liquidacao }, origem: :importacao, chave_idempotencia: chave)
    @item.update!(evento_financeiro: evento, lancamento_caixa: nil,
      estado_conciliacao: :evento_criado, decisao: "evento externo inequívoco",
      usuario_responsavel: @usuario, decidido_em: Time.current)
    @item
  end

  def classificar_descricao
    texto = @item.descricao.downcase
    return "aporte" if texto.match?(/aporte|dep[oó]sito|transfer[eê]ncia recebida/)
    return "resgate" if texto.match?(/resgate|retirada|transfer[eê]ncia enviada/)
  end

  def marcar_ambiguo
    @item.update!(estado_conciliacao: :ambiguo, decisao: "revisão manual necessária",
      usuario_responsavel: @usuario, decidido_em: Time.current)
    @item
  end
end
