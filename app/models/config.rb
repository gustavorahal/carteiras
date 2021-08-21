class Config < ApplicationRecord

  def self.busca_cotacao_enabled?(tipo_ativo)
    if tipo_ativo.downcase.in? Ativo.tipos_bolsa
      tipo = "bolsa"
    else
      tipo = tipo_ativo.downcase
    end

    config = Config.find_by(nome: "busca_cotacao_#{tipo}")
    if config
      ActiveModel::Type::Boolean.new.cast(config.valor)
    else
      # vamos assumir que se a configuração não existe, é porque não nos importamos em controla-la
      true
    end
  end

end