module Admin
  class FontesCotacaoController < CatalogosController
    self.model_class = FonteCotacao
    self.campos_permitidos = %i[codigo nome]
  end
end
