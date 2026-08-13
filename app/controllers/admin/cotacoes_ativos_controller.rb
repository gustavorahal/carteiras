module Admin
  class CotacoesAtivosController < BaseController
    def index
      @cotacoes = CotacaoAtivo.includes(:ativo, :fonte_cotacao, :autor).order(data: :desc)
    end

    def new
      @cotacao = CotacaoAtivo.new
    end

    def create
      resultado = Mercado.registrar_cotacao_ativo(ativo: Ativo.find(cotacao_params[:ativo_id]),
        data: cotacao_params[:data], preco: cotacao_params[:preco], fonte: FonteCotacao.find_by!(codigo: "MANUAL"),
        manual: true, usuario: current_user)
      redirect_to admin_cotacoes_ativos_path, notice: "Cotação #{resultado.estado}."
    rescue Financeiro::AtributosInvalidos, Financeiro::RegistroArquivado => e
      @cotacao = CotacaoAtivo.new(cotacao_params)
      flash.now[:alert] = e.detalhes.values.flatten.join(", ")
      render :new, status: :unprocessable_content
    end

    def update
      cotacao = CotacaoAtivo.find(params[:id])
      resultado = Mercado.registrar_cotacao_ativo(ativo: cotacao.ativo, data: cotacao.data,
        preco: cotacao_params[:preco], fonte: FonteCotacao.find_by!(codigo: "MANUAL"), manual: true, usuario: current_user)
      redirect_to admin_cotacoes_ativos_path, notice: "Cotação #{resultado.estado}."
    rescue Financeiro::AtributosInvalidos, Financeiro::RegistroArquivado => e
      @cotacoes = CotacaoAtivo.includes(:ativo, :fonte_cotacao, :autor).order(data: :desc)
      @cotacao_com_erro_id = params[:id].to_i
      @preco_invalido = params.dig(:cotacao_ativo, :preco)
      flash.now[:alert] = e.detalhes.values.flatten.join(", ")
      render :index, status: :unprocessable_content
    end

    def liberar_automacao
      Mercado.liberar_automacao(cotacao_ativo: CotacaoAtivo.find(params[:id]), usuario: current_user)
      redirect_to admin_cotacoes_ativos_path, notice: "Automação liberada."
    end

    private

    def cotacao_params = params.require(:cotacao_ativo).permit(:ativo_id, :data, :preco)
  end
end
