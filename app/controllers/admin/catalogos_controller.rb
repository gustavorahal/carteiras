module Admin
  class CatalogosController < BaseController
    before_action :carregar_registro, only: %i[show edit update arquivar restaurar]

    class_attribute :model_class, :campos_permitidos

    def index
      @registros = model_class.order(model_class.column_names.include?("nome") ? :nome : :id)
      render "admin/catalogos/index"
    end

    def show
      render "admin/catalogos/show"
    end

    def new
      @registro = model_class.new
      render "admin/catalogos/form"
    end

    def create
      @registro = model_class.new(registro_params)
      @registro.save!
      redirect_to action: :show, id: @registro.id, notice: "Cadastro criado."
    rescue ActiveRecord::RecordInvalid
      render "admin/catalogos/form", status: :unprocessable_content
    end

    def edit
      render "admin/catalogos/form"
    end

    def update
      @registro.update!(registro_params)
      redirect_to action: :show, id: @registro.id, notice: "Cadastro atualizado."
    rescue ActiveRecord::RecordInvalid
      render "admin/catalogos/form", status: :unprocessable_content
    end

    def arquivar
      @registro.arquivar!
      redirect_to action: :index
    end

    def restaurar
      @registro.restaurar!
      redirect_to action: :index
    end

    private

    def carregar_registro = @registro = model_class.find(params[:id])
    def registro_params = params.require(model_class.model_name.param_key).permit(*campos_permitidos)
  end
end
