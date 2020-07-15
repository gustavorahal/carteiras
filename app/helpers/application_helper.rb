module ApplicationHelper

  def display_porcentagem(valor)
    valor_per = number_to_percentage(valor.to_f, precision: 2)
    css_color = ""
    if valor > 0
      css_color = "text-success"
    elsif valor < 0
      css_color = "text-danger"
    end

    return "<span class=\"#{css_color}\">#{valor_per}</span>".html_safe
  end

  def diplay_moeda(valor)
    valor_currency = number_to_currency valor
    css_color = ""
    if valor > 0
      css_color = "text-success"
    elsif valor < 0
      css_color = "text-danger"
    end

    "<span class=\"#{css_color}\">#{valor_currency}</span>".html_safe
  end

end
