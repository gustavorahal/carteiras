require "test_helper"

class IntegridadeEsquemaTest < ActiveSupport::TestCase
  test "constraints do banco rejeitam sinais inválidos e códigos minúsculos" do
    assert_raises(ActiveRecord::StatementInvalid) do
      ActiveRecord::Base.transaction(requires_new: true) do
        Moeda.insert_all!([{ codigo: "eur", nome: "Euro", tipo: "fiduciaria", casas_decimais: 2,
          created_at: Time.current, updated_at: Time.current }])
      end
    end
    evento = EventoFinanceiro.create!(carteira: @carteira, usuario_responsavel: @usuario,
      tipo: :movimentacao_caixa, origem: :manual, estado: :rascunho, data_competencia: Date.current)
    assert_raises(ActiveRecord::StatementInvalid) do
      ActiveRecord::Base.transaction(requires_new: true) do
        MovimentacaoCaixa.insert_all!([{ evento_financeiro_id: evento.id, conta_caixa_id: @caixa_brl.id,
          natureza: "aporte", direcao: "entrada", valor: -1, data_efetiva: Date.current,
          created_at: Time.current, updated_at: Time.current }])
      end
    end
  end

  test "cadastros referenciados não podem ser apagados" do
    assert_raises(ActiveRecord::StatementInvalid) do
      ActiveRecord::Base.transaction(requires_new: true) { @brl.delete }
    end
    assert_raises(ActiveRecord::StatementInvalid) do
      ActiveRecord::Base.transaction(requires_new: true) { @corretora.delete }
    end
  end
end
