class Trade < ApplicationRecord
  belongs_to :ativo
  belongs_to :investidor
  belongs_to :carteira

  enum operacao: {
      compra: 1,
      venda: 2,
      resgate_ir: 3
  }

  enum mon_ou_des: {
      montagem: 1,
      desmontagem: 2
  }

end
