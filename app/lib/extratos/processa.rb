module Extratos
  class Processa

    @processa_class = nil

    def self.processar(conta_corrente)
      corretora_nome = conta_corrente.corretora.nome
      carteira = conta_corrente.carteira
      @processa_class = "Extratos::Processa#{corretora_nome.capitalize}".constantize

      conta_corrente.extratos.where(processado: false).each do |extrato|
        Rails.logger.info "Processando extrato id ##{extrato.id} '#{extrato.descricao}'"
        descricao = extrato.descricao
        provento_data = _get_provento(descricao)
        if provento_data
          _insere_provento(extrato, carteira, provento_data[:ativo],
                           provento_data[:quantidade], provento_data[:evento])
          next
        end

        movi_oper = _get_movimentaca(descricao)
        if movi_oper
          _insere_movimentacao(extrato, carteira)
          next
        end
      end
    end

    # @return nome movimentação ou nil
    def self._get_movimentaca(descr)
      movi_oper = nil
      if @processa_class.resgate?(descr)
        movi_oper = 'Resgate'
      elsif @processa_class.aporte?(descr)
        movi_oper = 'Aporte'
      end

      movi_oper
    end

    # @return {evento:, ativo:, quantidade:} OR nil
    def self._get_provento(descr)
      provento_data = nil
      evento = nil
      if @processa_class.dividendo(descr)
        provento_data = @processa_class.dividendo(descr)
        evento = 'dividendo'
      elsif @processa_class.jcp(descr)
        provento_data = @processa_class.jcp(descr)
        evento = 'jcp'
      elsif @processa_class.rendimento(descr)
        provento_data = @processa_class.rendimento(descr)
        evento = 'rendimento'
      end

      if provento_data
        nome_ativo = provento_data[0]
        quantidade = provento_data[1]
        ativo = Ativo.find_by(nome: nome_ativo)
        unless ativo
          Rails.logger.info "Ativo #{nome_ativo} não encontrado"
          return nil
        end
        { evento: evento, ativo: ativo, quantidade: quantidade }
      end
    end

    def self._insere_provento(extrato, carteira, ativo, quantidade, evento)
      valor_liquido = extrato.valor
      data = extrato.liquidacao
      moeda = extrato.conta_corrente.moeda
      corretora = extrato.conta_corrente.corretora
      Rails.logger.info("Inserindo #{evento} para carteira #{carteira.nome}: #{ativo.nome}, #{quantidade}, #{valor_liquido} #{data}")
      return unless Provento.find_by(extrato_id: extrato.id, carteira_id: carteira.id, ativo_id: ativo.id, quantidade: quantidade, data: data,
                                     valor_liquido: valor_liquido, moeda: moeda, evento: evento, corretora_id: corretora.id).nil?

      ActiveRecord::Base.transaction do
        Provento.create!(extrato_id: extrato.id, carteira_id: carteira.id, ativo_id: ativo.id, quantidade: quantidade, data: data,
                         valor_liquido: valor_liquido, moeda: moeda, evento: evento, corretora_id: corretora.id)
        extrato.processado = true
        extrato.save
      end
    end

    def self._insere_movimentacao(extrato, carteira)
      valor = extrato.valor
      data = extrato.liquidacao
      moeda = extrato.conta_corrente.moeda
      corretora = extrato.conta_corrente.corretora
      Rails.logger.info("Inserindo movimentação para carteira #{carteira.nome}: #{valor} em #{data}")
      return unless Movimentacao.find_by(extrato_id: extrato.id, carteira_id: carteira.id, valor: valor,
                                         moeda: moeda, data: data, corretora_id: corretora.id).nil?

      ActiveRecord::Base.transaction do
        Movimentacao.create!(extrato_id: extrato.id, carteira_id: carteira.id, valor: valor, moeda: moeda,
                             data: data, corretora_id: corretora.id)
        extrato.processado = true
        extrato.save
      end
    end
  end
end