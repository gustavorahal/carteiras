module Admin
  class Utils
    # Desmonta, ou seja, zera posicoes no ativo dado
    #
    # @return [Operacao]: operacao de desmontagem
    def self.desmonta_ativo(ativo, carteira, observacao, data, valor_unit: false)
      posicao_ativo = PosicaoAtivo.new(carteira, ativo, data)
      if posicao_ativo.quantidade.zero?
        Rails.logger.info "Quantidade de #{ativo.nome} é ZERO. Não há o que desmontar"
        return nil
      end
      valor_unit = posicao_ativo.preco_medio unless valor_unit.present?
      quantidade = posicao_ativo.quantidade
      corretora = _ultima_oper_corretora(ativo, carteira)

      Operacao.create!(ativo: ativo, carteira: carteira, corretora: corretora, data: data,
                       valor_unit: valor_unit, operacao: 'V', quantidade: quantidade, mon_ou_des: 'D',
                       observacao: observacao, operacao_sys: true)
    end

    # Compra ativo atraves de uma operacao
    #
    # @return [Operacao]: operacao de compra
    def self.compra_ativo(ativo, carteira, corretora, valor_unit, quantidade, observacao, data, montagem: false)
      Operacao.create!(ativo: ativo, carteira: carteira, corretora: corretora, data: data,
                       valor_unit: valor_unit, operacao: 'C', quantidade: quantidade, mon_ou_des: montagem ? 'M' : nil,
                       observacao: observacao, operacao_sys: true)
    end

    # Em quais carteiras dado ativo esta presente
    # @return lista de ActiveRecord Carteira
    def self.carteiras_with_ativo(ativo)
      carteiras = []
      Operacao.where(ativo: ativo).distinct(:carteira_id).pluck(:carteira_id).each do |carteira_id|
        carteiras.push Carteira.find(carteira_id)
      end
      carteiras
    end

    #
    # Private
    #

    def self._ultima_oper_corretora(ativo, carteira)
      ultima_operacao = Operacao.where(ativo: ativo, carteira: carteira).order(data: :desc).first
      ultima_operacao.corretora
    end

  end
end
