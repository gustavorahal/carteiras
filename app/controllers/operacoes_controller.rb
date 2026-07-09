class OperacoesController < ApplicationController

  before_action :set_vars, only: [:index, :new, :create, :edit, :update]

  def index
    @operacoes = policy_scope(@carteira.operacoes)
    @contas_correntes = policy_scope(@carteira.conta_correntes).includes(:corretora)
  end

  def new
    @operacao = Operacao.new
    # se tem permissão na carteira, então tb pode criar operacoes
    authorize @carteira
  end

  def create
    @operacao = @carteira.operacoes.new secure_params.except(:carteira_id)
    authorize @operacao

    if secure_params[:quantidade].blank? && secure_params[:valor_unit].blank?
      flash.now.alert = "Quantidade OU valor unitario precisam ser especificados"
      render 'new', status: :unprocessable_entity and return
    elsif secure_params[:valor].present?
      valor_unit = secure_params[:valor_unit]
      quantidade = secure_params[:quantidade]
      valor = secure_params[:valor]

      if valor_unit.present? && quantidade.blank?
        @operacao.quantidade = valor.to_f / valor_unit.to_f
      elsif quantidade.present? && valor_unit.blank?
        @operacao.valor_unit = valor.to_f / quantidade.to_f
      end
    end

    if @operacao.save
      redirect_to carteira_operacoes_path(carteira_id: params[:carteira_id]), notice: "Operação criada com sucesso!"
    else
      render 'new', status: :unprocessable_entity
    end


  end

  def edit
    @operacao = policy_scope(@carteira.operacoes).find params[:id]
    authorize @operacao
  end

  def update
    @operacao = policy_scope(@carteira.operacoes).find params[:id]
    authorize @operacao

    if @operacao.update(secure_params)
      redirect_to carteira_operacoes_path(carteira_id: params[:carteira_id]),
                                          notice: "Operação atualizada com sucesso!"
    else
      render 'edit'
    end
  end

  private

  def set_vars
    @carteira = policy_scope(Carteira).find params[:carteira_id]
    @ativos = policy_scope(Ativo).order(:nome)
    @corretoras = Corretora.all.order(:nome)
  end

  def secure_params
    params.require(:operacao).permit(:ativo_id, :corretora_id, :carteira_id,
                                     :data, :valor_unit, :quantidade, :valor,
                                     :operacao, :usdbrl, :observacao, :operacao_sys, :co_corretagem, :co_taxa,
                                     :co_emolumentos, :co_iss_iof, :co_irrf, :co_outros)
  end

end
