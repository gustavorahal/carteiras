require 'test_helper'

class OperacaoTest < ActiveSupport::TestCase

  def setup
    @cc = conta_correntes(:vitreo_brl)
    @carteira = @cc.carteira
    @corretora = @cc.corretora
    @ativo = ativos(:bpan4)
    @ultimo_extrato = @cc.extratos.last
  end

  def descricao_operacao(operacao)
    "Operação ID##{operacao.id}"
  end

  test "entrada temporária do extrato adicionada se data da operação é posterior a última entrada de extrato" do
    op = Operacao.create(data: @ultimo_extrato.movimentacao + 1.day,
                    operacao: 'C',
                    quantidade: 100, valor_unit: 11,
                    ativo: @ativo,
                    carteira: @carteira,
                    corretora: @corretora)

    assert Extrato.find_by(descricao: descricao_operacao(op),
                           temporario: true, valor: op.saldo_financeiro)
  end

  test "entrada extrato NÃO adicionada se data anterior a ultimo extrato" do
    op = Operacao.create(data: @ultimo_extrato.movimentacao - 1.day,
                         operacao: 'C',
                         quantidade: 100, valor_unit: 11,
                         ativo: @ativo,
                         carteira: @carteira,
                         corretora: @corretora)

    assert_nil Extrato.find_by(descricao: descricao_operacao(op),
                           temporario: true, valor: op.saldo_financeiro)
  end

  test "entrada extrato atualizada após edição de operação" do
    op = Operacao.create(data: @ultimo_extrato.movimentacao + 1.day,
                         operacao: 'C',
                         quantidade: 100, valor_unit: 11,
                         ativo: @ativo,
                         carteira: @carteira,
                         corretora: @corretora)

    assert Extrato.find_by(descricao: descricao_operacao(op),
                               temporario: true, valor: op.saldo_financeiro)

    valor_antigo = op.saldo_financeiro
    op.quantidade = 101
    op.save!
    valor_novo = op.saldo_financeiro

    assert_nil Extrato.find_by(descricao: descricao_operacao(op),
                           temporario: true, valor: valor_antigo)
    assert Extrato.find_by(descricao: descricao_operacao(op),
                               temporario: true, valor: valor_novo)
  end
end
