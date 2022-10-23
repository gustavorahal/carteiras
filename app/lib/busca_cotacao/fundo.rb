require 'open-uri' # para 'open' não conflitar com Kernel.open
require 'csv'

module BuscaCotacao
  #
  # Busca informações de fundos na base de dados da CVM
  #
  class Fundo

    @url_cvm = 'http://dados.cvm.gov.br/dados/FI/DOC/INF_DIARIO/DADOS'

    def self.busca(cnpj, data)
      arquivo_csv = _busca_arquivo_cvm(data.year, data.month)

      valor_cota = nil
      # Headers arquivo CSV: CNPJ_FUNDO;DT_COMPTC;VL_TOTAL;VL_QUOTA;VL_PATRIM_LIQ;CAPTC_DIA;RESG_DIA;NR_COTST
      CSV.foreach(arquivo_csv, headers: true, col_sep: ';') do |row|
        if row['CNPJ_FUNDO'] == cnpj && row['DT_COMPTC'].to_date == data
          valor_cota = row['VL_QUOTA'].to_f
        end
      end

      valor_cota
    end


    #
    # Private
    #

    # Busca o arquivo de dados na data especificada
    #
    # @return nome do arquivo baixado
    def self._busca_arquivo_cvm(num_ano, num_mes)
      nome_arquivo_cvm = "inf_diario_fi_#{num_ano}#{'%02d' % num_mes}.zip"
      nome_arquivo_cvm_unzipped = nome_arquivo_cvm.gsub(".zip", ".csv")
      baixado_timestamp = nome_arquivo_cvm_unzipped + "#{Date.today.strftime('%F')}"

      # Podemos aproveitar o arquivo já baixado se foi baixado hoje
      # e portanto não terá novas atualizações
      if File.exist?(baixado_timestamp) &&
        baixado_timestamp.gsub(nome_arquivo_cvm_unzipped,'').to_date == Date.today
        Rails.logger.info "Arquivo CVM #{nome_arquivo_cvm_unzipped} já baixado, reutilizando-o"
        return nome_arquivo_cvm_unzipped
      else
        FileUtils.touch baixado_timestamp
      end
      # Podemos aproveitar também o arquivo já baixado se viramos o mês e portanto
      # ele já contém todos os dados daquele mês
      if (File.exist? nome_arquivo_cvm_unzipped) &&
                (Date.today.month != num_mes && Date.today.year != num_ano)
        Rails.logger.info "Arquivo CVM #{nome_arquivo_cvm_unzipped} já baixado, reutilizando-o"
        return nome_arquivo_cvm_unzipped
      end

      url_arquivo = "#{@url_cvm}/#{nome_arquivo_cvm}"
      Rails.logger.info "Baixando arquivo CSV em #{url_arquivo}"

      download = URI.parse(url_arquivo).open
      IO.copy_stream(download, nome_arquivo_cvm)

      # Descomprimir
      `unzip -o #{nome_arquivo_cvm}`

      nome_arquivo_cvm_unzipped
    end

  end
end