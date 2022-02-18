require 'open-uri' # para 'open' não conflitar com Kernel.open

module BuscaCotacao
  class Tesouro

    def self.get_url(ano, titulo_tipo)
      "https://cdn.tesouro.gov.br/sistemas-internos/apex/producao/sistemas/sistd/#{ano}/#{titulo_tipo}_#{ano}.xls"
    end

    def self.titulos
      { 'Tesouro IPCA+ 2024' => { tipo: 'NTN-B_Principal', codigo: 'NTN-B Princ 150824' },
        'Tesouro IPCA+ 2026' => { tipo: 'NTN-B_Principal', codigo: 'NTN-B Princ 150826' },
        'Tesouro IPCA+ 2035' => { tipo: 'NTN-B_Principal', codigo: 'NTN-B Princ 150535' },
        'Tesouro IPCA+ com Juros Semestrais 2026' => { tipo: 'NTN-B', codigo: 'NTN-B 150826' },
        'Tesouro IPCA+ com Juros Semestrais 2050' => { tipo: 'NTN-B', codigo: 'NTN-B 150850' },
        'Tesouro IPCA+ com Juros Semestrais 2055' => { tipo: 'NTN-B', codigo: 'NTN-B 150555' },
        'Tesouro Prefixado 2023' => { tipo: 'LTN', codigo: 'LTN 010123' },
        'Tesouro Prefixado 2024' => { tipo: 'LTN', codigo: 'LTN 010724' },
        'Tesouro Prefixado 2025' => { tipo: 'LTN', codigo: 'LTN 010125' },
        'Tesouro Prefixado com Juros Semestrais 2029' => { tipo: 'NTN-F', codigo: 'NTN-F 010129' },
        'Tesouro Selic 2023' => { tipo: 'LFT', codigo: 'LFT 010323' },
        'Tesouro Selic 2025' => { tipo: 'LFT', codigo: 'LFT 010325' },
        'Tesouro Selic 2027' => { tipo: 'LFT', codigo: 'LFT 010327' }
      }
    end

    # @return dados: Array de data e preços [(data1, preço1), ...] para todo o ano corrente
    # data é um objeto Date.
    def self.busca(titulo, data)
      unless titulo.in? titulos
        Rails.logger.error "Não sei como buscar dados para #{titulo}"
        return nil
      end

      titulo_codigo = titulos[titulo][:codigo]
      titulo_tipo = titulos[titulo][:tipo]
      ano = data.year.to_s

      arquivo_excel = _busca_arquivo_tesouro(get_url(ano, titulo_tipo), titulo_codigo, data.year)
      return nil unless arquivo_excel

      abre_xls = Roo::Spreadsheet.open(arquivo_excel, extension: :xls)
      sheet = abre_xls.sheet(titulo_codigo)
      # Headers na linha 2:
      # Dia	Taxa Compra Manhã	Taxa Venda Manhã	PU Compra Manhã	PU Venda Manhã	PU Base Manhã
      # TODO: checa header para validar formato do arquivo
      headers = sheet.row(2)
      dados = {}
      i = 3
      loop do
        row = sheet.row(i)
        begin
          row_data = row[0].to_date
        rescue Date::Error, NoMethodError
          # fim de arquivo
          break
        end
        valor = row[5] # PU Base Manhã -> é o que a XP usa
        dados[row_data] = valor
        i += 1
      end

      data.in?(dados.keys) ? dados : nil
    end


    #
    # Private
    #

    # Busca o arquivo de dados na data especificada
    #
    # @return nome do arquivo baixado
    def self._busca_arquivo_tesouro(url, codigo, ano)
      nome_arquivo = "#{codigo.gsub(' ', '_')}_#{ano}.xls"
      Rails.logger.info "Baixando arquivo Tesouro para #{codigo} #{ano} em #{url}"

      # Apesar de tentador, fazer o cache desse arquivo tem alcance limitado porque o mesmo
      # e atualizado diariamente e nosso backend tb faz buscas diarios, tornando sem eficacia esse cache
      begin
        download = URI.parse(url).open
        IO.copy_stream(download, nome_arquivo)
      rescue Net::OpenTimeout
        Rails.logger.error "Erro baixando arquivo #{url}"
        return nil
      end

      nome_arquivo
    end
  end
end