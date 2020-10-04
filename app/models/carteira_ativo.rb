class CarteiraAtivo < ApplicationRecord
  has_many :operacoes
  belongs_to :corretora
  belongs_to :ativo
  belongs_to :carteira

  validates :ativo_id, uniqueness: { scope: [ :carteira_id, :corretora_id ] }

  # Utilizado em formulários
  def nome_amigavel
    "#{ativo.nome_amigavel} - #{corretora.nome}"
  end

end
