require "test_helper"

class ConcorrenciaConfirmacaoTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  teardown do
    ActiveRecord::Base.connection.disable_referential_integrity do
      ActiveRecord::Base.connection.tables.excluding("schema_migrations", "ar_internal_metadata").each do |tabela|
        ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{ActiveRecord::Base.connection.quote_table_name(tabela)} RESTART IDENTITY CASCADE")
      end
    end
  end

  test "duas confirmações concorrentes na mesma carteira não perdem atualização" do
    ids = { carteira: @carteira.id, usuario: @usuario.id, conta: @conta.id, ativo: @ativo.id,
      moeda: @brl.id }
    inicio = Queue.new
    erros = Queue.new
    threads = 2.times.map do |indice|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          inicio.pop
          RegistrarOperacao.call(carteira: Carteira.find(ids[:carteira]), usuario: User.find(ids[:usuario]),
            atributos: { conta_investimento_id: ids[:conta], ativo_id: ids[:ativo], natureza: :compra,
              quantidade: 1, preco_unitario: 10 + indice, moeda_id: ids[:moeda],
              data_negociacao: Date.new(2026, 1, 10), data_liquidacao: Date.new(2026, 1, 12),
              taxa: 0, emolumentos: 0, corretagem: 0, iss_iof: 0, irrf: 0, outros: 0,
              taxa_conversao_base: 1, taxa_conversao_fiscal: 1 })
        end
      rescue StandardError => e
        erros << e
      end
    end
    2.times { inicio << true }
    threads.each(&:join)
    assert erros.empty?, (erros.pop.full_message unless erros.empty?)
    assert_equal 2.to_d, PosicaoAtual.find_by!(conta_investimento_id: ids[:conta], ativo_id: ids[:ativo]).quantidade
    assert_equal [1, 2], EventoFinanceiro.confirmado.order(:sequencia_na_data).pluck(:sequencia_na_data)
  end

  test "duas confirmações do mesmo rascunho são idempotentes" do
    rascunho = RegistrarOperacao.call(carteira: @carteira, usuario: @usuario,
      atributos: atributos_operacao(natureza: :compra, quantidade: 1, preco: 10), confirmar: false)
    inicio = Queue.new
    erros = Queue.new
    threads = 2.times.map do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          inicio.pop
          ConfirmarEventoFinanceiro.call(EventoFinanceiro.find(rascunho.id))
        end
      rescue StandardError => e
        erros << e
      end
    end
    2.times { inicio << true }
    threads.each(&:join)

    assert erros.empty?, (erros.pop.full_message unless erros.empty?)
    assert_equal 1, rascunho.reload.lancamentos_caixa.count
    assert_equal 1.to_d, PosicaoAtual.find_by!(conta_investimento: @conta, ativo: @ativo).quantidade
  end
end
