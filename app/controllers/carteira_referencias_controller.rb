class CarteiraReferenciasController < ApplicationController

  before_action :set_vars, only: [:edit, :update, :create, :new]
  before_action :set_carteira_ativo, only: [:edit, :update]

  def index
    @view = params[:view]
    @data_fim = Date.today
    @carteira = Carteira.find params[:carteira_id]
    @carteira_ativos = @carteira.carteira_ativos.where(valido: true).order(:book).order('ativos.nome')

    if @view == 'atual_vs_ref'
      @carteira_posicao = CarteiraPosicao.new(@carteira, @data_fim)
      @carteira_ativos_posicao = @carteira_posicao.carteira_ativos
      carteira_ativos_soma_tmp = @carteira_ativos_posicao.union(@carteira_ativos)
      # reordena por book
      @carteira_ativos_soma = {}
      carteira_ativos_soma_tmp.each do |ca|
        @carteira_ativos_soma[ca.book] = [] unless ca.book.in? @carteira_ativos_soma
        @carteira_ativos_soma[ca.book].push ca
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
      @carteira_ativo.valido = true
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
                                           :book, :porcentagem, :valido, :corretora_id)
  end

end