# Classe de permissão base. A ideia é que ela seja super restritiva e seletivamente
# as subclasses vão relaxando as permissões.
class ApplicationPolicy < Struct.new(:user, :record)

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
    return false unless respond_to? :user

    if record.respond_to? :investidor
      user&.investidor.id == record.investidor.id
    elsif record.respond_to? :carteira
      user&.investidor.id == record.carteira.investidor.id
    else
      false
    end
  end

  def scope
    Pundit.policy_scope!(user, record.class)
  end
end
