module Admin
  class Incorporar

    def self.incorporar(ativo_incorporado, ativo_incorporadora, taxa, data)
      Utils.carteiras_with_ativo(ativo_incorporado).each do |carteira|
        _incorporar_ativo_carteira(ativo_incorporado, ativo_incorporadora, carteira, taxa, data)
      end
    end

    # A incorporação de ações é um mecanismo que garante que todas as ações de uma empresa (incorporada)
    # sejam adquiridas por outra companhia (incorporadora). Após o processo, a companhia
    # incorporada vira uma subsidiária integral da incorporadora
    # @param taxa: o quanto da incorporada representa em acoes da incorporadora.
    #              Ex. GNDI3 foi incorporada a HAPV3 a uma taxa de 5,2436, ou seja,
    #                  o acionista recebera 5,2436 acoes de HAPV3 para cada 1 de GNDI3.
    def self._incorporar_ativo_carteira(ativo_incorporado, ativo_incorporadora, carteira, taxa, data)
      raise StandardError "Ativo #{ativo_incorporado.nome} não é desdobravel ou grupável" unless ativo_incorporado.na_bolsa?
      raise StandardError "Ativo #{ativo_incorporadora.nome} não é desdobravel ou grupável" unless ativo_incorporadora.na_bolsa?

      # Passo 1. Desmontar ativo incorporado com valor_unit == valor_medio (para ficar no zero a zero)
      # Passo 2. Montar ativo incorporadora com nova quantidade e valor_unit do desdobramento
      Operacao.transaction do
        # Passo 1
        obs = "Incorporado a #{ativo_incorporadora.nome} à taxa #{taxa}"
        cotacao_hoje = CotacaoService.cotacao(ativo_incorporado, data)
        oper_desmontagem = Utils.desmonta_ativo(ativo_incorporado, carteira, obs, data, valor_unit: cotacao_hoje.valor_unit)
        # nesse caso nao 'e possivel fazer incorporacao se nao temos sucesso em desmontar
        return nil if oper_desmontagem.blank?

        # Passo 2
        pa_incorporadora = PosicaoAtivo.new(carteira, ativo_incorporadora, data)
        quant = oper_desmontagem.quantidade * taxa
        # Arredondar para baixo, visto que nao teria sentido "ganhar" mais acoes com o arredondamento pora cima
        # Em geral, o restante volta em forma de dinheiro na CC da corretora
        # Como op de desmontagem 'e quant negativo, tornar positivo antes de floor usando 'abs'
        quant = quant.abs.floor
        corretora = oper_desmontagem.corretora
        obs = "Incorporação de #{ativo_incorporado.nome} à taxa #{taxa}"
        cotacao_hoje = CotacaoService.cotacao(ativo_incorporadora, data)
        Utils.compra_ativo(ativo_incorporadora, carteira, corretora, cotacao_hoje.valor_unit, quant, obs, data, montagem: pa_incorporadora.quantidade.zero?)
      end

    end

  end
end