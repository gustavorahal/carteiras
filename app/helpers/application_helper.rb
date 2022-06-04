module ApplicationHelper

  def display_numero(numero)
    number_with_delimiter numero
  end

  def display_data(data)
    l(data, format: :default)
  end

  def display_mes_ano(data)
    l(data, format: '%b %Y')
  end

  def display_porcentagem(valor, cores: false)
    valor_per = number_to_percentage(valor.to_f, precision: 2)
    css_color = ""
    if cores
      if valor > 0
        css_color = "text-success"
      elsif valor < 0
        css_color = "text-danger"
      end
    end

    "<span class=\"#{css_color}\">#{valor_per}</span>".html_safe
  end

  # @param max_precision: mostra o número sem qualquer arredondamento, mostrando
  #                       todas as casas decimais.
  def display_moeda(valor, moeda: 'BRL', cores: false, max_precision: false)
    unidade = 'R$'
    unidade = 'US$' if moeda == 'USD'

    if max_precision
      valor_currency = variable_precision_currency valor, unit: unidade
    else
      valor_currency = number_to_currency valor, precision: 2, unit: unidade
    end

    css_color = ""

    if cores
      if valor > 0
        css_color = "text-success"
      elsif valor < 0
        css_color = "text-danger"
      end
    end

    "<span class=\"#{css_color}\">#{valor_currency}</span>".html_safe
  end

  # https://stackoverflow.com/questions/3320051/using-a-dynamic-precision-value-in-number-to-currency-based-on-the-decimal-value
  def variable_precision_currency(valor, min_precision: 2, unit: unidade)
    num = BigDecimal(valor.to_s)
    prec = (num - num.floor).to_s.length - 2
    prec = min_precision if prec < min_precision
    number_to_currency(num, precision: prec, unit: unit)
  end

end
