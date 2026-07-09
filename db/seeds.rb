[
  ["USDBRL", "BRL"],
  ["BRLUSD", "USD"],
  ["BTCBRL", "BRL"]
].each do |nome, moeda_negociacao|
  Ativo.find_or_create_by!(nome: nome) do |ativo|
    ativo.tipo = "moeda"
    ativo.moeda_negociacao = moeda_negociacao
    ativo.moeda_exposicao = moeda_negociacao
    ativo.descricao = "Par de moedas #{nome}"
  end
end
