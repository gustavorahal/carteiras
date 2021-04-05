class CotacaoService

  # param @ativo: ActiceRecord Ativo
  # param @data: irá tentar buscar cotacao para data dada. Se não for possivel, retornar
  #              ultimo dia antes da data com uma cotacao disponivel
  def self.cotacao(ativo, data)
    Rails.cache.fetch("cotacao_ativo_#{ativo.id}_#{data}", expires_in: 20.seconds) do
      cotacao = Cotacao.where(ativo: ativo, data: data).order(data: :desc).first
      if cotacao.nil?
        Rails.logger.info "Cotação para #{ativo.nome}: não encontrado no BD em #{data}, vamos resolver"
        cotacao = _resolve_cotacao(ativo, data)
      end

      cotacao
    end
  end

  def self.cotacao_usdbrl(data)
    cotacao(Ativo.find_by_nome('USDBRL'), data)
  end

  def self.cotacao_brlusd(data)
    cotacao(Ativo.find_by_nome('BRLUSD'), data)
  end

  # Buscar cotação de todos ativos presentes nas diferentes carteiras
  # Útil para rodar diariamente e proativamente já buscar e registrar as
  # cotações
  def self.busca_e_registra_tudo(data)
    # Mesmo que os ativos se repitam nas carteiras, a primeira
    # vez que ele vai aparecer vai acontecer a busca pela cotacao
    # e nas subsequente vezes, vai encontrar no banco e não buscar mais.
    Carteira.all.each do |carteira|
      # No interessa saber quais os ativos 'hoje' presentes
      # nas carteiras e a partir deles, dai sim buscar suas
      # cotações na data informada
      ca = CarteiraAtivos.new(carteira, Date.today)
      ca.ativos.each { |ativo| cotacao(ativo, data) }
    end
  end


  #
  # Métodos privados
  #

  # Encontra uma cotacão mais adequada de acordo com a data informada
  def self._resolve_cotacao(ativo, data)
    data_ajustada = Utils.ajusta_data(data, ativo)
    ultima_cotacao = Cotacao.where(ativo: ativo).order(data: :desc).first

    # Se eu pedi cotaçao para data de hoje (e não tem no BD), supõem-se então
    # que eu queira a data mais próxima
    if ultima_cotacao && ultima_cotacao.data > data_ajustada && data == Date.today
      Rails.logger.info "Cotação para #{ativo.nome}: retornando última cotação disponível no BD em #{ultima_cotacao.data}"
      return ultima_cotacao
    end

    if data_ajustada != data
      Rails.logger.info "Cotação para #{ativo.nome}: data ajustada de #{data} para #{data_ajustada}"
    end

    cotacao = Cotacao.where(ativo: ativo, data: data_ajustada).order(data: :desc).first
    if cotacao
      Rails.logger.info "Cotação para #{ativo.nome}: cotação em #{data_ajustada} disponível no BD"
    else
      Rails.logger.info "Cotação para #{ativo.nome}: não encontranda no BD em #{data_ajustada}, buscando"
      cotacao = send("_busca_e_registra_#{ativo.tipo.downcase}", ativo, data_ajustada)
    end

    cotacao
  end

  #
  # Pela maneira que nossa Backend funciona, esta função faz algo
  # atipico. Aproveitando que a busca é custosa (download de arquivo de 30MB+)
  # e retorna informações de todos os fundos, vamos aproveitar e atualizar
  # informações de todos os fundos mas retornar só o que foi pedido
  def self._busca_e_registra_fundo(ativo, data)
    cnpjs = Ativo.where(tipo: 'fundo').pluck(:cnpj)
    dados = BuscaFundos.busca(cnpjs, data.year, data.month)
    dados.each do |cnpj, vl_cotas|
      vl_cotas.each do |vl_cota|
        ativo = Ativo.find_by(cnpj: cnpj)
        data = vl_cota[0].to_date
        unless Cotacao.find_by(ativo: ativo, data: data)
          Cotacao.create!(ativo: ativo, data: data, valor_unit: vl_cota[1])
        end
      end
    end

    Cotacao.find_by(ativo: ativo, data: data)
  end


  # @return Cotacao ActiveRecord object
  def self._busca_e_registra_criptomoeda(ativo, data)
    _busca_e_registra_moeda(ativo, data)
  end

  # @return Cotacao ActiveRecord object
  def self._busca_e_registra_moeda(ativo, data)
    preco = BuscaMoeda.busca(ativo, data)
    Cotacao.create!(ativo_id: ativo.id, valor_unit: preco, data: data)
  end

  # @return Cotacao ActiveRecord object
  def self._busca_e_registra_tesouro(ativo, data)
    data_api, preco = BuscaTesouro.busca ativo.nome
    # Ignoramos a data_api e consideramos a data fornecida porque
    # a api sempre vai no fornecer a ultima data disponivel
    Cotacao.create!(ativo_id: ativo.id, valor_unit: preco, data: data)
  end

  # @return Cotacao ActiveRecord object
  def self._busca_e_registra_bolsa(ativo, data)
    data_efetiva, preco = BuscaBolsa.busca(ativo, data)

    if preco.nil?
      Rails.logger.info("Cotação para #{ativo.nome}: não encontrei preço em #{data_efetiva}, pegando última cotação")
      Cotacao.where(ativo_id: ativo.id).last
    else
      # Como podemos ter escolhido uma data diferente da fornecida, ver se já temos o registro
      # dela e "sobreescrever"
      Cotacao.find_by(ativo: ativo, data: data_efetiva).try(:destroy)
      Cotacao.create!(ativo: ativo, data: data_efetiva, valor_unit: preco)
    end
  end

  def self._busca_e_registra_fii(ativo, data)
    _busca_e_registra_bolsa(ativo, data)
  end

  def self._busca_e_registra_etf(ativo, data)
    _busca_e_registra_bolsa(ativo, data)
  end

  def self._busca_e_registra_acao(ativo, data)
    _busca_e_registra_bolsa(ativo, data)
  end

  def self._busca_e_registra_cra(ativo, data)
    # como não temos um jeito automatizado de buscar cra ou debenture
    # retornar ultima cotação
    Cotacao.where(ativo: ativo).order(data: :desc).first
  end

  def self._busca_e_registra_debenture(ativo, data)
    # como não temos um jeito automatizado de buscar cra ou debenture
    # retornar ultima cotação
    _busca_e_registra_cra(ativo, data)
  end

end
