class OperacoesController < ApplicationController

  before_action :set_vars, only: [:index, :new, :create, :edit]

  def index
    @operacoes = @carteira.operacoes
    # refazemos a query sem reusar a de cima porque o uso de "order by" acima
    # complica o uso do distinct depois
    @operacoes_hoje = Operacao.where(carteira: @carteira, data: Date.today)
  end

  def new
    @operacao = Operacao.new
  end

  def create
    @operacao = Operacao.new secure_params

    if @operacao.save
      redirect_to carteira_operacoes_path carteira_id: params[:carteira_id]
    else
      render 'new'
    end
  end

  def edit
    @operacao = Operacao.find params[:id]
  end

  def update
    @operacao = Operacao.find params[:id]
    if @operacao.update(secure_params)
      redirect_to carteira_operacoes_path carteira_id: params[:carteira_id],
                                          notice: "Operação atualizada com sucesso!"
    else
      render 'edit'
    end
  end

  private

  def set_vars
    @carteira = Carteira.find params[:carteira_id]
    @ativos = Ativo.all.order(:nome)
    @corretoras = Corretora.all.order(:nome)
  end

  def secure_params
    params.require(:operacao).permit(:ativo_id, :corretora_id, :carteira_id,
                                     :data, :valor_unit, :quantidade,
                                     :operacao, :usdbrl, :observacao, :operacao_sys, :co_corretagem, :co_taxa,
                                     :co_emolumentos, :co_iss_iof, :co_irrf, :co_outros)
  end

end