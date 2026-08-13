class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index? = leitura?
  def show? = leitura?
  def create? = edicao?
  def new? = create?
  def update? = edicao?
  def edit? = update?
  def destroy? = edicao?

  def leitura?
    user&.administrador_sistema? || (espaco && user&.pode_ler?(espaco))
  end

  def edicao?
    return false if espaco&.arquivado?
    return false if record.respond_to?(:arquivado?) && record.arquivado?
    return false if ascendencia_arquivada?
    user&.administrador_sistema? || (espaco && user&.pode_editar?(espaco))
  end

  def administracao?
    return false if espaco&.arquivado?
    user&.administrador_sistema? || (espaco && user&.pode_administrar?(espaco))
  end

  private

  def ascendencia_arquivada?
    return true if record.respond_to?(:investidor) && record.investidor&.arquivado?
    return true if record.respond_to?(:carteira) && record.carteira&.arquivado?
    return true if record.respond_to?(:conta_investimento) && record.conta_investimento&.arquivado?
    false
  end

  def espaco
    return record if record.is_a?(Espaco)
    return record.espaco if record.respond_to?(:espaco)
    return record.investidor.espaco if record.respond_to?(:investidor) && record.investidor
    return record.carteira.espaco if record.respond_to?(:carteira) && record.carteira
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.all if user&.administrador_sistema?
      return scope.none unless user

      case model.name
      when "Espaco" then scope.joins(:membros_espaco).where(membros_espaco: { user_id: user.id })
      when "Investidor" then scope.joins(espaco: :membros_espaco).where(membros_espaco: { user_id: user.id })
      when "Carteira" then scope.joins(investidor: { espaco: :membros_espaco }).where(membros_espaco: { user_id: user.id })
      when "ContaInvestimento" then scope.joins(carteira: { investidor: { espaco: :membros_espaco } }).where(membros_espaco: { user_id: user.id })
      when "TransacaoFinanceira" then scope.joins(investidor: { espaco: :membros_espaco }).where(membros_espaco: { user_id: user.id })
      else scope.none
      end.distinct
    end

    private

    def model = scope.respond_to?(:klass) ? scope.klass : scope
  end
end
