class Cotacao < ApplicationRecord
  belongs_to :ativo

  after_save :delete_cache

  enum fonte: {
    yahoo_finance_rapidapi: 1,
    marketstack: 2,
    cvm_gov: 3,
    tesouro_gov: 4,
    bcb_gov: 5,
    coingecko_rapidapi: 6,
    currency_converter_rapidapi: 7
  }

  private

  def delete_cache
    CacheService.delete_cotacao(ativo, data)
  end
end
