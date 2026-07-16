brl = Moeda.find_or_create_by!(codigo: "BRL") do |moeda|
  moeda.nome = "Real brasileiro"
  moeda.tipo = :fiduciaria
  moeda.casas_decimais = 2
end

Moeda.find_or_create_by!(codigo: "USD") do |moeda|
  moeda.nome = "Dólar americano"
  moeda.tipo = :fiduciaria
  moeda.casas_decimais = 2
end

FonteCotacao.find_or_create_by!(nome: "Manual") do |fonte|
  fonte.prioridade = 0
  fonte.tipos_atendidos = %w[ativo cambio]
end

FonteCotacao.find_or_create_by!(nome: "Yahoo Finance") do |fonte|
  fonte.prioridade = 10
  fonte.tipos_atendidos = %w[acao fii etf moeda]
end

if ENV["ADMIN_EMAIL"].present?
  usuario = User.find_or_initialize_by(email: ENV.fetch("ADMIN_EMAIL"))
  usuario.password = ENV.fetch("ADMIN_PASSWORD")
  usuario.role = :admin
  usuario.save!
  Investidor.find_or_create_by!(user: usuario) do |investidor|
    investidor.nome = ENV.fetch("ADMIN_NOME", "Administrador")
    investidor.moeda_fiscal = brl
  end
end
