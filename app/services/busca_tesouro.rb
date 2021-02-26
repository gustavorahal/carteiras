require 'open-uri' # para 'open' não conflitar com Kernel.open

class BuscaTesouro

  def self.busca(titulo)
    titulos = { 'Tesouro IPCA+ 2024' => 'https://taxas-tesouro.com/resgatar/tesouro-ipca+-2024/',
                'Tesouro IPCA+ 2035' => 'https://taxas-tesouro.com/resgatar/tesouro-ipca+-2035/',
                'Tesouro IPCA+ com Juros Semestrais 2026' => 'https://taxas-tesouro.com/resgatar/tesouro-ipca+-com-juros-semestrais-2026/',
                'Tesouro IPCA+ com Juros Semestrais 2050' => 'https://taxas-tesouro.com/resgatar/tesouro-ipca+-com-juros-semestrais-2050/',
                'Tesouro IPCA+ com Juros Semestrais 2055' => 'https://taxas-tesouro.com/resgatar/tesouro-ipca+-com-juros-semestrais-2055/',
                'Tesouro Prefixado 2023' => 'https://taxas-tesouro.com/resgatar/tesouro-prefixado-2023/',
                'Tesouro Prefixado 2025' => 'https://taxas-tesouro.com/resgatar/tesouro-prefixado-2025/',
                'Tesouro Prefixado com Juros Semestrais 2029' => 'https://taxas-tesouro.com/resgatar/tesouro-prefixado-com-juros-semestrais-2029/',
                'Tesouro Selic 2023' => 'https://taxas-tesouro.com/resgatar/tesouro-selic-2023/',
                'Tesouro Selic 2025' => 'https://taxas-tesouro.com/resgatar/tesouro-selic-2025/',
                'Tesouro Selic 2027' => 'https://taxas-tesouro.com/resgatar/tesouro-selic-2027/'}

    return unless titulo.in? titulos

    document = Nokogiri::HTML.parse(URI.parse(titulos[titulo]).open)
    tags = document.xpath("//span[@class='ml-1 sm:text-xl']")
    # conversão manual do formato pt_BR para en_US
    preco = tags[3].text.gsub('R$ ', '').gsub('.','').gsub(',', '.')
    data_str = tags[4].text
    data = Time.zone.parse(data_str).to_datetime

    [data, preco]
  end

end