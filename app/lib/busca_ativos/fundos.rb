require 'open-uri' # para 'open' não conflitar com Kernel.open
require 'csv'

module BuscaAtivos
  #
  # Busca informações de fundos na base de dados da CVM
  #
  class Fundos

    @url_cvm = 'http://dados.cvm.gov.br/dados/FI/DOC/INF_DIARIO/DADOS'

    def self.busca(cnpjs, num_ano, num_mes)
      raise TypeError unless cnpjs.is_a? Array

      arquivo_csv = _busca_arquivo_cvm(num_ano, num_mes)

      dados = {}
      # Headers arquivo CSV: CNPJ_FUNDO;DT_COMPTC;VL_TOTAL;VL_QUOTA;VL_PATRIM_LIQ;CAPTC_DIA;RESG_DIA;NR_COTST
      CSV.foreach(arquivo_csv, headers: true, col_sep: ';') do |row|
        if row['CNPJ_FUNDO'].in? cnpjs
          dados[row['CNPJ_FUNDO']] = [] unless dados.has_key? row['CNPJ_FUNDO']
          dados[row['CNPJ_FUNDO']].push [ row['DT_COMPTC'], row['VL_QUOTA'].to_f ]
        end
      end

      dados
    end


    #
    # Private
    #

    # Busca o arquivo de dados na data especificada
    #
    # @return nome do arquivo baixado
    def self._busca_arquivo_cvm(num_ano, num_mes)
      nome_arquivo_cvm = "inf_diario_fi_#{num_ano}#{'%02d' % num_mes}.csv"
      # Só podemos aproveitar o arquivo já baixado se já viramos o mês e portanto
      # ele já contém todos os dados daquele mês
      if (File.exist? nome_arquivo_cvm) &&
                (Date.today.month != num_mes && Date.today.year != num_ano)
        return nome_arquivo_cvm
      end

      url_arquivo = "#{@url_cvm}/#{nome_arquivo_cvm}"
      Rails.logger.info "Baixando arquivo CSV em #{url_arquivo}"

      download = URI.parse(url_arquivo).open
      IO.copy_stream(download, nome_arquivo_cvm)

      nome_arquivo_cvm
    end

  end
end