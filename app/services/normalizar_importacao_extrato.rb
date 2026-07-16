require "csv"
require "digest"

class NormalizarImportacaoExtrato
  FORMATOS = %w[xp vitreo avenue].freeze

  def self.call(conta_caixa:, arquivo:, formato:, nome_original: nil)
    new(conta_caixa, arquivo, formato, nome_original).call
  end

  def initialize(conta_caixa, arquivo, formato, nome_original)
    @conta_caixa = conta_caixa
    @arquivo = arquivo
    @caminho = arquivo.respond_to?(:path) ? arquivo.path : arquivo.to_s
    @formato = formato.to_s.downcase
    @nome = nome_original || (arquivo.respond_to?(:original_filename) ? arquivo.original_filename : File.basename(@caminho))
  end

  def call
    raise ArgumentError, "Formato de extrato não suportado" unless @formato.in?(FORMATOS)
    checksum = Digest::SHA256.file(@caminho).hexdigest
    existente = ImportacaoExtrato.find_by(conta_caixa: @conta_caixa, checksum_sha256: checksum)
    return existente if existente

    linhas = send("ler_#{@formato}")
    ImportacaoExtrato.transaction do
      importacao = ImportacaoExtrato.create!(conta_caixa: @conta_caixa,
        corretora: @conta_caixa.corretora, nome_original: @nome, checksum_sha256: checksum,
        formato: @formato, estado: :normalizada, total_itens: linhas.size,
        itens_pendentes: linhas.size)
      agora = Time.current
      importacao.itens.insert_all!(linhas.each_with_index.map do |linha, indice|
        linha.merge(ordem: indice + 1, moeda_id: @conta_caixa.moeda_id,
          chave_deduplicacao: chave_deduplicacao(linha), dados_normalizados: linha,
          estado_conciliacao: "pendente", created_at: agora, updated_at: agora)
      end)
      importacao
    end
  rescue ActiveRecord::RecordNotUnique
    ImportacaoExtrato.find_by!(conta_caixa: @conta_caixa, checksum_sha256: checksum)
  end

  private

  def ler_xp
    planilha = Roo::Excelx.new(@caminho).sheet(0)
    cabecalho = planilha.row(14)
    raise ArgumentError, "Extrato XP em formato inválido" unless cabecalho[0, 5] == ["Movimentação", "Liquidação", "Lançamento", cabecalho[3], "Valor (R$)"]
    ler_linhas_planilha(planilha, 15, 0, 1, 2, 4, 5)
  end

  def ler_vitreo
    planilha = Roo::Excelx.new(@caminho).sheet(0)
    cabecalho = planilha.row(1)
    esperado = ["Movimentação", "Liquidação", "Tipo", "Descrição", "Valor de transação", "Saldo"]
    raise ArgumentError, "Extrato Vitreo em formato inválido" unless cabecalho[0, 6] == esperado
    ler_linhas_planilha(planilha, 2, 0, 1, 3, 4, nil)
  end

  def ler_avenue
    tabela = CSV.read(@caminho, headers: true, col_sep: ";")
    raise ArgumentError, "Extrato Avenue em formato inválido" if tabela.headers.size < 5
    tabela.filter_map do |linha|
      next if linha[0].blank?
      montar_linha(linha[0], linha[2], linha[3], Utils.decimal_from_br_number(linha[4]),
        linha[5].present? ? Utils.decimal_from_br_number(linha[5]) : nil,
        linha.headers.index { |h| h.to_s.downcase.include?("identificador") }&.then { |i| linha[i] })
    end
  end

  def ler_linhas_planilha(planilha, inicio, mov, liq, descricao, valor, saldo)
    linhas = []
    indice = inicio
    loop do
      linha = planilha.row(indice)
      break if linha[mov].blank?
      linhas << montar_linha(linha[mov], linha[liq], linha[descricao].to_s.delete_prefix("* PROV * "),
        Utils.decimal(linha[valor]), saldo && Utils.decimal(linha[saldo]), nil)
      indice += 1
    end
    linhas
  end

  def montar_linha(movimentacao, liquidacao, descricao, valor, saldo, identificador)
    {
      data_movimentacao: Date.parse(movimentacao.to_s),
      data_liquidacao: Date.parse((liquidacao.presence || movimentacao).to_s),
      descricao: descricao.to_s.strip, valor:, saldo_informado: saldo,
      identificador_externo: identificador.presence
    }
  end

  def chave_deduplicacao(linha)
    Digest::SHA256.hexdigest([
      @conta_caixa.id, linha[:data_movimentacao], linha[:data_liquidacao],
      linha[:descricao].to_s.downcase.squish, linha[:valor], linha[:identificador_externo]
    ].join("|"))
  end
end
