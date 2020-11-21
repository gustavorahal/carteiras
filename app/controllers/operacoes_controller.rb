class OperacoesController < ApplicationController

  def index
    @carteira = Carteira.find params[:carteira_id]
    @operacoes = @carteira.operacoes
  end

  def new
    @carteira = Carteira.find params[:carteira_id]
    @operacao = Operacao.new
    @carteira_ativos = @carteira.carteira_ativos_todos
  end

  def create
    @operacao = Operacao.new secure_params
    @operacao.corretora_id = @operacao.carteira_ativo.corretora_id
    @operacao.ativo_id = @operacao.carteira_ativo.ativo_id
    @operacao.carteira_id = @operacao.carteira_ativo.carteira_id
    @operacao.usdbrl = if @operacao.ativo.usd?
                         CotacaoService.cotacao_usdbrl(@operacao.data).valor_unit
                       else
                         1
                       end

    if @operacao.save
      redirect_to carteira_operacoes_path carteira_id: params[:carteira_id]
    else
      render 'new'
    end
  end

  def edit
    @carteira = Carteira.find params[:carteira_id]
    @operacao = Operacao.find params[:id]
    # pego todos os ativos porque posso estar editando operações de ativos não mais válidos
    @carteira_ativos = @carteira.carteira_ativos_todos
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

  def secure_params
    params.require(:operacao).permit(:carteira_ativo_id, :mon_ou_des,
                                     :data, :valor_unit, :quantidade,
                                     :operacao, :usdbrl, :observacao, :co_corretagem, :co_taxa,
                                     :co_emolumentos, :co_iss_iof, :co_irrf, :co_outros)
  end

end