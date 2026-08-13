module Admin
  class InstituicoesController < CatalogosController
    self.model_class = Instituicao
    self.campos_permitidos = %i[nome]
  end
end
