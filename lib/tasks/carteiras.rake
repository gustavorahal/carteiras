namespace :carteiras do
  desc "Reconstrói as posições atuais de todas as carteiras ou de CARTEIRA_ID"
  task reconstruir_posicoes: :environment do
    escopo = ENV["CARTEIRA_ID"].present? ? Carteira.where(id: ENV.fetch("CARTEIRA_ID")) : Carteira.all
    escopo.find_each { |carteira| ReconstruirPosicoesCarteira.call(carteira:) }
  end
end
