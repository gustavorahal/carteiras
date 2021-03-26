require 'test_helper'

class ReferenciaAtivoTest < ActiveSupport::TestCase
  test "ativo só pode aparecer uma vez em referência" do
    ra = referencia_ativos(:itsa4)
    error = assert_raises(ActiveRecord::RecordInvalid) {
      ReferenciaAtivo.create!(ativo: ra.ativo, referencia: ra.referencia, book: 'foobar', porcentagem: 1)
    }

    assert_equal 'A validação falhou: Ativo já está em uso', error.message
  end
end
