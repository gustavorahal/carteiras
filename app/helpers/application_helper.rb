module ApplicationHelper

  def display_numero(numero)
    number_to_human numero, precision: 10
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

  def display_moeda(valor, moeda: 'BRL', cores: false)
    unidade = 'R$'
    unidade = 'US$' if moeda == 'USD'

    valor_currency = variable_precision_currency valor, 2, unidade
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
  def variable_precision_currency(valor, min_precision, unidade)
    num = BigDecimal(valor.to_s)
    prec = (num - num.floor).to_s.length - 2
    prec = min_precision if prec < min_precision
    number_to_currency(num, precision: prec, unit: unidade)
  end

end
