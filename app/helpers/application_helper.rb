module ApplicationHelper

  def display_numero(numero)
    number_to_human numero, precision: 10
  end

  def display_data(data)
    I18n.l data, format: :default
  end

  def display_porcentagem(valor, cores = FALSE)
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

    valor_currency = number_to_currency valor, unit: unidade
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

end
