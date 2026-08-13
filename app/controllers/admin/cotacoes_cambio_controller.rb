module Admin
  class CotacoesCambioController < BaseController
    def index
      @cotacoes = CotacaoCambio.includes(:moeda_origem, :moeda_destino, :autor).order(data: :desc)
    end

    def new
      @cotacao = CotacaoCambio.new
    end

    def create
      registrar
      redirect_to admin_cotacoes_cambio_path, notice: "Cotação registrada."
    rescue Financeiro::AtributosInvalidos, Financeiro::RegistroArquivado => e
      @cotacao = CotacaoCambio.new(cotacao_params)
      flash.now[:alert] = e.detalhes.values.flatten.join(", ")
      render :new, status: :unprocessable_content
    end

    def update
      cotacao = CotacaoCambio.find(params[:id])
      Mercado.registrar_cotacao_cambio(moeda_origem: cotacao.moeda_origem, moeda_destino: cotacao.moeda_destino,
        data: cotacao.data, taxa: cotacao_params[:taxa], usuario: current_user)
      redirect_to admin_cotacoes_cambio_path, notice: "Cotação atualizada."
    rescue Financeiro::AtributosInvalidos, Financeiro::RegistroArquivado => e
      @cotacoes = CotacaoCambio.includes(:moeda_origem, :moeda_destino, :autor).order(data: :desc)
      @cotacao_com_erro_id = params[:id].to_i
      @taxa_invalida = params.dig(:cotacao_cambio, :taxa)
      flash.now[:alert] = e.detalhes.values.flatten.join(", ")
      render :index, status: :unprocessable_content
    end

    private

    def registrar
      Mercado.registrar_cotacao_cambio(moeda_origem: Moeda.find(cotacao_params[:moeda_origem_id]),
        moeda_destino: Moeda.find(cotacao_params[:moeda_destino_id]), data: cotacao_params[:data],
        taxa: cotacao_params[:taxa], usuario: current_user)
    end
    def cotacao_params = params.require(:cotacao_cambio).permit(:moeda_origem_id, :moeda_destino_id, :data, :taxa)
  end
end
