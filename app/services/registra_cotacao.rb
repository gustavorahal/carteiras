class RegistraCotacao

  def self.brl_usd
    preco = BuscaCotacao.brl_usd
    ativo = Ativo.find_by_nome 'CURRENCY:BRLUSD'
    Cotacao.create(ativo_id: ativo.id, valor_unit: preco, data: DateTime.now)
    puts "Cotação BRLUSD: #{preco}"
  end

  def self.usd_brl
    preco = BuscaCotacao.usd_brl
    ativo = Ativo.find_by_nome 'CURRENCY:USDBRL'
    Cotacao.create(ativo_id: ativo.id, valor_unit: preco, data: DateTime.now)
  end

  def self.btc_brl
    preco = BuscaCotacao.btc_brl
    ativo = Ativo.find_by_nome 'CURRENCY:BTCBRL'
    Cotacao.create(ativo_id: ativo.id, valor_unit: preco, data: DateTime.now)
  end

  def self.tesouro
    Ativo.tesouro.each do |ativo|
      data, preco = BuscaCotacao.tesouro ativo.nome
      ativo = Ativo.find_by_nome ativo.nome
      Cotacao.create(ativo_id: ativo.id, valor_unit: preco, data: data)
    end
  end

  def self.acoes_e_fii
    Ativo.all.each do |ativo|
      next unless ativo.tipo.in? ['acao','fii']

      ativo_str = ativo.nome
      if ativo.moeda == 'BRL'
        ativo_str = ativo_str + '.SA'
      end

      # Já foi atualizado na ultima meia hora? Então ignora. Evita fazer muitas chamadas para API
      if Cotacao.where(ativo_id: ativo.id).where('created_at > ?', 30.minutes.ago).exists?
        Rails.logger.info "#{ativo.nome} já atualizado na última hora, pulando"
        next
      end

      preco = BuscaCotacao.acao(ativo_str).to_f

      Cotacao.create(ativo_id: ativo.id, valor_unit: preco, data: DateTime.now)
    end
  end

  def self.fundo_xp_dolar
    ativo = Ativo.find_by_nome 'VOTORANTIM FIC FI CAMBIAL DÓLAR'
    data, preco = BuscaCotacao.fundo_xp_dolar
    Cotacao.create(ativo_id: ativo.id, valor_unit: preco, data: data)
  end

  def self.registra_tudo
    acoes_e_fii
    btc_brl
    usd_brl
    brl_usd
    tesouro
    fundo_xp_dolar
  end


end
