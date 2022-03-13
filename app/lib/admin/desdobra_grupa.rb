module Admin
  class DesdobraGrupa

    # O desdobramento de ações consiste na divisão do número de ações em circulação de uma empresa,
    # com o objetivo de reduzir o preço dos ativos e aumentar a liquidez no mercado acionário
    def self.desdobrar(ativo, n_vezes, data)
      Utils.carteiras_with_ativo(ativo).each do |carteira|
        _desdobrar_ativo_carteira(ativo, carteira, n_vezes, data)
      end
    end

    # O grupamento, também chamado de inplit, consiste em agrupar
    # várias ações e as transforma em apenas uma.
    # O objetivo da companhia com essa estratégia é aumentar o preço dos papéis.
    # Em alguns casos, isso facilita a negociação.
    def self.grupar(ativo, n_vezes, data)
      Utils.carteiras_with_ativo(ativo).each do |carteira|
        _grupar_ativo_carteira(ativo, carteira, n_vezes, data)
      end
    end


    #
    # Private
    #

    def self._desdobrar_ativo_carteira(ativo, carteira, n_vezes, data)
      _desdobra_ou_grupa(ativo, carteira, n_vezes, 'D', data)
    end

    def self._grupar_ativo_carteira(ativo, carteira, n_vezes, data)
      _desdobra_ou_grupa(ativo, carteira, n_vezes, 'G', data)
    end

    def self._desdobra_ou_grupa(ativo, carteira, n_vezes, desdobra_ou_grupa, data)
      raise StandardError "Ativo #{ativo.nome} não é desdobravel ou grupável" unless ativo.na_bolsa?

      # Passo 1. Desmontar posicao atual com valor_unit == valor_medio (para ficar no zero a zero)
      # Passo 2. Montar posicao atual com nova quantidade e valor_unit do desdobramento
      #
      # É necessário marcar como montagem e desmontagem senão o valor de calculo do preço_medio
      # pós desdobramento não ficaria correto. Precisamos de fato recomeçar
      Operacao.transaction do
        observacao = "Desdobramento/Grupamento por #{n_vezes}x. Desmontando"
        oper_desmontagem = Utils.desmonta_ativo(ativo, carteira, observacao, data)

        case desdobra_ou_grupa
        when 'D'
          quant = oper_desmontagem.quantidade * n_vezes
          valor_unit = oper_desmontagem.valor_unit / n_vezes
        when 'G'
          quant = oper_desmontagem.quantidade / n_vezes
          valor_unit = oper_desmontagem.valor_unit * n_vezes
        else
          raise StandardError 'Operação inválida'
        end

        observacao = "Desdobramento/Grupamento por #{n_vezes}x. Montando"
        Utils.compra_ativo(ativo, carteira, valor_unit, quant, observacao, data, montagem: true)
      end
    end

  end
end