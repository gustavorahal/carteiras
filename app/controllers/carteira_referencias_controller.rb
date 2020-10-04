class CarteiraReferenciasController < ApplicationController

  before_action :set_vars, only: [:edit, :update, :create, :new, :index]
  before_action :set_carteira_ativo, only: [:edit, :update]

  def index
    @view = params[:view]
    @carteira_ativos = @carteira.carteira_ativos_validos_por_book

    # NOTA: Esta view só funciona com o momento atual, não é possivel resgatar a história
    # de referência da carteira pela maneira que armazenamos este histórico.
    if @view == 'atual_vs_ref'
      @carteira_posicao = CarteiraPosicao.new(@carteira, @data)
      @carteira_posicao_caps = @carteira_posicao.carteira_ativos_posicoes
      @carteira_ativos_posicoes = []
      @carteira_ativos.each { |ca| @carteira_ativos_posicoes.push CarteiraAtivoPosicao.new(ca, @data) }
      carteira_ativos_posicoes_soma_tmp = @carteira_posicao_caps.union(@carteira_ativos_posicoes)
      # reordena por book
      @carteira_ativos_posicoes_soma = {}
      carteira_ativos_posicoes_soma_tmp.each do |cap|
        book = cap.carteira_ativo.book
        @carteira_ativos_posicoes_soma[book] = [] unless book.in? @carteira_ativos_posicoes_soma
        @carteira_ativos_posicoes_soma[book].push cap
      end
    end
  end

  def new
    @carteira_ativo = CarteiraAtivo.new
  end

  def create
    @carteira_ativo = CarteiraAtivo.find_by carteira_id: @carteira.id,
                                            ativo_id: secure_params[:ativo_id],
                                            corretora_id: secure_params[:corretora_id]
    if @carteira_ativo
      # já existe o ativo adicionado, vamos reutilizado
      @carteira_ativo.porcentagem = secure_params[:porcentagem]
    else
      @carteira_ativo = CarteiraAtivo.new secure_params
      @carteira_ativo.carteira = @carteira
    end

    if @carteira_ativo.save
      redirect_to carteira_carteira_referencias_path(@carteira, view: 'ref'),
                                                    notice: "Ativo referência #{@carteira_ativo.ativo.nome} atualizado com sucesso!"
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    if @carteira_ativo.update(secure_params)
      redirect_to carteira_carteira_referencias_path(@carteira, view: 'ref'),
                  notice: "Ativo referência #{@carteira_ativo.ativo.nome} atualizado com sucesso!"
    else
      render 'edit'
    end
  end


  private

  def set_vars
    @ativos = Ativo.all.order(:nome)
    @carteira = Carteira.find params[:carteira_id]
    @corretoras = Corretora.all.order(:nome)
  end

  def set_carteira_ativo
    @carteira_ativo = CarteiraAtivo.includes(:operacoes, :ativo).find(params[:id])
  end

  def secure_params
    params.require(:carteira_ativo).permit(:carteira_id, :ativo_id,
                                           :book, :porcentagem, :corretora_id)
  end

end