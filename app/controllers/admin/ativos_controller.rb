module Admin
  class AtivosController < CatalogosController
    self.model_class = Ativo
    self.campos_permitidos = %i[codigo mercado descricao tipo moeda_negociacao_id simbolo_yahoo cnpj]
  end
end
