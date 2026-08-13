require "test_helper"

class ConcorrenciaTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  teardown do
    tabelas = ActiveRecord::Base.connection.tables - %w[schema_migrations ar_internal_metadata]
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{tabelas.map { |t| ActiveRecord::Base.connection.quote_table_name(t) }.join(', ')} RESTART IDENTITY CASCADE")
  end

  test "confirmações simultâneas recebem ordens distintas sem perder projeção" do
    rascunhos = 2.times.map do |indice|
      TransacoesFinanceiras.criar_rascunho(tipo: "nota_negociacao", investidor: @investidor,
        usuario: @usuario, atributos: atributos_nota(quantidade: "#{indice + 1}"))
    end
    erros = Queue.new
    prontos = Queue.new
    iniciar = Queue.new
    threads = rascunhos.map do |rascunho|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          prontos << true
          iniciar.pop
          TransacoesFinanceiras.confirmar(transacao: TransacaoFinanceira.find(rascunho.id), usuario: User.find(@usuario.id))
        rescue StandardError => e
          erros << e
        end
      end
    end
    2.times { prontos.pop }
    2.times { iniciar << true }
    threads.each(&:join)
    assert erros.empty?, -> { erros.pop.full_message }
    assert_equal [1, 2], TransacaoFinanceira.confirmadas.order(:ordem_na_data).pluck(:ordem_na_data)
    assert_equal BigDecimal("3"), PosicaoAtual.find_by!(ativo: @ativo).quantidade
  end

  test "duas remoções simultâneas preservam um administrador" do
    segundo = @espaco.membros_espaco.create!(user: @estranho, papel: "administrador")
    ids = [@espaco.membros_espaco.find_by!(user: @usuario).id, segundo.id]
    resultados = Queue.new
    threads = ids.map do |id|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          resultados << MembroEspaco.find(id).destroy
        end
      end
    end
    threads.each(&:join)
    assert_equal 1, 2.times.count { resultados.pop == false }
    assert_equal 1, @espaco.membros_espaco.reload.where(papel: "administrador").count
  end

  test "atualização e confirmação concorrentes nunca divergem detalhe e projeção" do
    rascunho = TransacoesFinanceiras.criar_rascunho(tipo: "nota_negociacao", investidor: @investidor,
      usuario: @usuario, atributos: atributos_nota(quantidade: "1"))
    prontos = Queue.new
    iniciar = Queue.new
    erros = Queue.new
    operacoes = [
      -> {
        TransacoesFinanceiras.atualizar_rascunho(transacao: TransacaoFinanceira.find(rascunho.id),
          usuario: User.find(@usuario.id), atributos: atributos_nota(quantidade: "2"))
      },
      -> {
        TransacoesFinanceiras.confirmar(transacao: TransacaoFinanceira.find(rascunho.id), usuario: User.find(@usuario.id))
      }
    ]
    threads = operacoes.map do |operacao|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          prontos << true
          iniciar.pop
          operacao.call
        rescue Financeiro::EstadoInvalido
          nil
        rescue StandardError => e
          erros << e
        end
      end
    end
    2.times { prontos.pop }
    2.times { iniciar << true }
    threads.each(&:join)

    assert erros.empty?, -> { erros.pop.full_message }
    confirmada = TransacaoFinanceira.find(rascunho.id)
    assert confirmada.confirmada?
    assert_equal confirmada.nota_negociacao.negociacoes.first.quantidade,
      PosicaoAtual.find_by!(ativo: @ativo).quantidade
  end
end
