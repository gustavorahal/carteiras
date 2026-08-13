Moeda.find_or_create_by!(codigo: "BRL") do |moeda|
  moeda.nome = "Real brasileiro"
  moeda.casas_decimais = 2
end

Moeda.find_or_create_by!(codigo: "USD") do |moeda|
  moeda.nome = "Dólar americano"
  moeda.casas_decimais = 2
end

FonteCotacao.find_or_create_by!(codigo: "MANUAL") { |fonte| fonte.nome = "Manual" }
FonteCotacao.find_or_create_by!(codigo: "YAHOO") { |fonte| fonte.nome = "Yahoo Finance" }

email = ENV["ADMIN_EMAIL"]&.strip&.downcase.presence
senha = ENV["ADMIN_PASSWORD"].presence
raise "ADMIN_EMAIL e ADMIN_PASSWORD devem estar ambos presentes ou ambos ausentes" if email.present? != senha.present?
if Rails.env.production? && !email && !User.exists?(administrador_sistema: true)
  raise "ADMIN_EMAIL e ADMIN_PASSWORD são obrigatórios no primeiro preparo de produção"
end

if email
  usuario = User.find_or_initialize_by(email:)
  usuario.password = senha
  usuario.administrador_sistema = true
  usuario.save!
end
