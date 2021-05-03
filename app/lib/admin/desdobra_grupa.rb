module Admin
  class DesdobraGrupa

    # O desdobramento de ações consiste na divisão do número de ações em circulação de uma empresa,
    # com o objetivo de reduzir o preço dos ativos e aumentar a liquidez no mercado acionário
    def self.desdobrar(ativo, n_vezes)
      _carteiras_with_ativo(ativo).each do |carteira|
        desdobrar_ativo_carteira(ativo, carteira, n_vezes)
      end
    end

    # O grupamento, também chamado de inplit, consiste em agrupar
    # várias ações e as transforma em apenas uma.
    # O objetivo da companhia com essa estratégia é aumentar o preço dos papéis.
    # Em alguns casos, isso facilita a negociação.
    def self.grupar(ativo, n_vezes)
      _carteiras_with_ativo(ativo).each do |carteira|
        grupar_ativo_carteira(ativo, carteira, n_vezes)
      end
    end

    def self.desdobrar_ativo_carteira(ativo, carteira, n_vezes)
      _desdobra_ou_grupa(ativo, carteira, n_vezes, 'D')
    end

    def self.grupar_ativo_carteira(ativo, carteira, n_vezes)
      _desdobra_ou_grupa(ativo, carteira, n_vezes, 'G')
    end


    #
    # Private
    #


    def self._desdobra_ou_grupa(ativo, carteira, n_vezes, desdobra_ou_grupa)
      raise StandardError "Ativo #{ativo.nome} não é desdobravel ou grupável" unless ativo.na_bolsa?

      # Passo 1. Desmontar posicao atual com valor_unit == valor_medio (para ficar no zero a zero)
      # Passo 2. Montar posicao atual com nova quantidade e valor_unit do desdobramento
      #
      # É necessário marcar como montagem e desmontagem senão o valor de calculo do preço_medio
      # pós desdobramento não ficaria correto. Precisamos de fato recomeçar
      posicao_ativo = PosicaoAtivo.new(carteira, ativo, Date.today)
      preco_medio = posicao_ativo.preco_medio
      quantidade = posicao_ativo.quantidade
      if quantidade.zero?
        Rails.logger.info "Quantidade de #{ativo.nome} é ZERO. Não há o que desdobrar ou grupar"
        return nil
      end

      ultima_operacao = Operacao.where(ativo: ativo, carteira: carteira).order(data: :desc).first
      corretora = ultima_operacao.corretora
      case desdobra_ou_grupa
      when 'D'
        nova_quant = quantidade * n_vezes
        novo_valor_unit = preco_medio / n_vezes
        obs_str = "Desdobramento"
      when 'G'
        nova_quant = quantidade / n_vezes
        novo_valor_unit = preco_medio * n_vezes
        obs_str = "Grupamento"
      else
        raise StandardError 'Operação inválida'
      end

      data = Date.today

      Operacao.transaction do
        # Desmontar
        Operacao.create!(ativo: ativo, carteira: carteira, corretora: corretora, data: data,
                         valor_unit: preco_medio, operacao: 'V', quantidade: quantidade, mon_ou_des: 'D',
                         observacao: "#{obs_str} por #{n_vezes}x. Desmontando", operacao_sys: true)
        # Montar
        Operacao.create!(ativo: ativo, carteira: carteira, corretora: corretora, data: data,
                         valor_unit: novo_valor_unit, operacao: 'C', quantidade: nova_quant, mon_ou_des: 'M',
                         observacao: "#{obs_str} por #{n_vezes}x. Montando", operacao_sys: true)
      end
    end

    # Em quais carteiras dado ativo esta presente
    # @return lista de ActiveRecord Carteira
    def self._carteiras_with_ativo(ativo)
      carteiras = []
      Operacao.where(ativo: ativo).distinct(:carteira_id).pluck(:carteira_id).each do |carteira_id|
        carteiras.push Carteira.find(carteira_id)
      end
      carteiras
    end

  end
end