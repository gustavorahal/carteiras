require 'open-uri' # para 'open' não conflitar com Kernel.open

module BuscaAtivos
  class Tesouro
    def self.urls
      { '2021': { 'LFT' => 'https://sisweb.tesouro.gov.br/apex/cosis/sistd/obtem_arquivo/462:100856',
                  'LTN' => 'https://sisweb.tesouro.gov.br/apex/cosis/sistd/obtem_arquivo/461:83786',
                  'NTN-C' => 'https://sisweb.tesouro.gov.br/apex/cosis/sistd/obtem_arquivo/463:41358',
                  'NTN-B' => 'https://sisweb.tesouro.gov.br/apex/cosis/sistd/obtem_arquivo/466:75189',
                  'NTN-B Princ' => 'https://sisweb.tesouro.gov.br/apex/cosis/sistd/obtem_arquivo/465:866272',
                  'NTN-F' => 'https://sisweb.tesouro.gov.br/apex/cosis/sistd/obtem_arquivo/464:18443' },
        '2020': { 'LFT' => 'https://sisweb.tesouro.gov.br/apex/cosis/sistd/obtem_arquivo/444:79907',
                  'LTN' => 'https://sisweb.tesouro.gov.br/apex/cosis/sistd/obtem_arquivo/446:74455',
                  'NTN-C' => 'https://sisweb.tesouro.gov.br/apex/cosis/sistd/obtem_arquivo/442:38266',
                  'NTN-B' => 'https://sisweb.tesouro.gov.br/apex/cosis/sistd/obtem_arquivo/445:803682',
                  'NTN-B Princ' => 'https://sisweb.tesouro.gov.br/apex/cosis/sistd/obtem_arquivo/443:40624',
                  'NTN-F' => 'https://sisweb.tesouro.gov.br/apex/cosis/sistd/obtem_arquivo/441:145250' },
        '2019': { 'LFT' => 'https://sisweb.tesouro.gov.br/apex/cosis/sistd/obtem_arquivo/421:82660',
                  'LTN' => 'https://sisweb.tesouro.gov.br/apex/cosis/sistd/obtem_arquivo/402:98996',
                  'NTN-C' => 'https://sisweb.tesouro.gov.br/apex/cosis/sistd/obtem_arquivo/403:39498',
                  'NTN-B' => 'https://sisweb.tesouro.gov.br/apex/cosis/sistd/obtem_arquivo/404:16583',
                  'NTN-B Princ' => 'https://sisweb.tesouro.gov.br/apex/cosis/sistd/obtem_arquivo/405:864412',
                  'NTN-F' => 'https://sisweb.tesouro.gov.br/apex/cosis/sistd/obtem_arquivo/406:73329' }
      }
    end

    def self.titulos
      { 'Tesouro IPCA+ 2024' => { tipo: 'NTN-B Princ', codigo: 'NTN-B Princ 150824' },
        'Tesouro IPCA+ 2035' => { tipo: 'NTN-B Princ', codigo: 'NTN-B Princ 150535' },
        'Tesouro IPCA+ com Juros Semestrais 2026' => { tipo: 'NTN-B', codigo: 'NTN-B 150826' },
        'Tesouro IPCA+ com Juros Semestrais 2050' => { tipo: 'NTN-B', codigo: 'NTN-B 150850' },
        'Tesouro IPCA+ com Juros Semestrais 2055' => { tipo: 'NTN-B', codigo: 'NTN-B 150555' },
        'Tesouro Prefixado 2023' => { tipo: 'LTN', codigo: 'LTN 010123' },
        'Tesouro Prefixado 2025' => { tipo: 'LTN', codigo: 'LTN 010125' },
        'Tesouro Prefixado com Juros Semestrais 2029' => { tipo: 'NTN-F', codigo: 'NTN-F 010129' },
        'Tesouro Selic 2023' => { tipo: 'LFT', codigo: 'LFT 010323' },
        'Tesouro Selic 2025' => { tipo: 'LFT', codigo: 'LFT 010325' },
        'Tesouro Selic 2027' => { tipo: 'LFT', codigo: 'LFT 010327' }
      }
    end

    def self.busca(titulo, data)
      raise StandardError, "Não sei como buscar dados para #{titulo}" unless titulo.in? titulos

      titulo_codigo = titulos[titulo][:codigo]
      titulo_tipo = titulos[titulo][:tipo]
      ano_sym = data.year.to_s.to_sym

      arquivo_excel = _busca_arquivo_tesouro(urls[ano_sym][titulo_tipo], titulo_codigo, data.year)
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
          data = row[0].to_date
        rescue Date::Error, NoMethodError
          # fim de arquivo
          break
        end
        valor = row[4] # PU (preço unitário) Venda Manhã
        dados[data] = valor
        i += 1
      end

      dados
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

      download = URI.parse(url).open
      IO.copy_stream(download, nome_arquivo)

      nome_arquivo
    end
  end
end