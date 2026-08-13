class MembrosEspacoController < ApplicationController
  before_action :carregar_espaco

  def create
    membro = @espaco.membros_espaco.new(papel: membro_params[:papel])
    authorize membro
    user = User.find_by(email: params.require(:membro_espaco)[:email].to_s.strip.downcase)
    return redirect_to(@espaco, alert: "Usuário cadastrado não encontrado.") unless user
    membro.user = user
    membro.save!
    redirect_to @espaco, notice: "Membro adicionado."
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
    redirect_to @espaco, alert: e.record.errors.full_messages.to_sentence
  end

  def update
    membro = @espaco.membros_espaco.find(params[:id])
    authorize membro
    membro.update!(papel: membro_params[:papel])
    redirect_to @espaco, notice: "Papel atualizado."
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
    redirect_to @espaco, alert: e.record.errors.full_messages.to_sentence
  end

  def destroy
    membro = @espaco.membros_espaco.find(params[:id])
    authorize membro
    membro.destroy!
    redirect_to @espaco, notice: "Membro removido."
  rescue ActiveRecord::RecordNotDestroyed => e
    redirect_to @espaco, alert: e.record.errors.full_messages.to_sentence
  end

  private

  def membro_params = params.require(:membro_espaco).permit(:papel)
end
