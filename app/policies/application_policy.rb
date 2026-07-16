# Classe de permissão base. A ideia é que ela seja super restritiva e seletivamente
# as subclasses vão relaxando as permissões.
class ApplicationPolicy < Struct.new(:user, :record)
  class Scope < Struct.new(:user, :scope)
    def resolve
      return scope.all if user&.admin?
      return scope.none unless user&.investidor? && user.investidor.present?

      if scoped_model.column_names.include?('investidor_id')
        scope.where(investidor: user.investidor)
      elsif scoped_model.reflect_on_association(:carteira)
        scope.joins(:carteira).where(carteiras: { investidor_id: user.investidor.id })
      else
        scope.none
      end
    end

    private

    def scoped_model
      scope.respond_to?(:klass) ? scope.klass : scope
    end
  end

  def index?
    admin? || owner?
  end

  def show?
    admin? || owner?
  end

  def create?
    admin? || owner?
  end

  def new?
    admin? || owner?
  end

  def update?
    admin? || owner?
  end

  def edit?
    admin? || owner?
  end

  def destroy?
    admin? || owner?
  end



  def admin?
    user&.admin?
  end

  def owner?
    return false if record.is_a? Symbol
    return false unless user&.investidor

    # em caso de novos objetos ex. Operacao.new, apesar do método que aponta para outro objeto (ex.
    # investidor) estar presente, o mesmo não esta instanciado (nil), portanto checar isso.
    if record.respond_to?(:investidor) && record.investidor.present?
      user.investidor.id == record.investidor.id
    elsif record.respond_to?(:carteira) && record.carteira.present?
      user.investidor.id == record.carteira.investidor.id
    elsif record.respond_to?(:conta_investimento) && record.conta_investimento.present?
      user.investidor.id == record.conta_investimento.carteira.investidor.id
    elsif record.respond_to?(:conta_caixa) && record.conta_caixa.present?
      user.investidor.id == record.conta_caixa.carteira.investidor.id
    else
      false
    end
  end

  def scope
    Pundit.policy_scope!(user, record.class)
  end
end
