class Moedas
  include ActiveSupport::Configurable
  config_accessor :ativo_usdbrl
end

Moedas.config.ativo_usdbrl = Ativo.find_by_nome('CURRENCY:USDBRL')
Moedas.config.ativo_brlusd = Ativo.find_by_nome('CURRENCY:BRLUSD')
Moedas.config.ativo_btcbrl = Ativo.find_by_nome('CURRENCY:BTCBRL')
