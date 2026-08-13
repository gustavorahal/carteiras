module Admin
  class MoedasController < CatalogosController
    self.model_class = Moeda
    self.campos_permitidos = %i[codigo nome casas_decimais]
  end
end
