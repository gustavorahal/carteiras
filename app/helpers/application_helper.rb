module ApplicationHelper
  STATUS_CLASSES = {
    "rascunho" => "text-bg-secondary", "confirmada" => "text-bg-success", "revertida" => "text-bg-warning",
    "analisada" => "text-bg-info", "pendente" => "text-bg-warning", "concluida" => "text-bg-success",
    "falhou" => "text-bg-danger", "arquivado" => "text-bg-secondary", "ativo" => "text-bg-success",
    "calculado" => "text-bg-success", "incompleto" => "text-bg-warning",
    "sem_patrimonio_inicial_valido" => "text-bg-secondary", "corte_saldo_inicial" => "text-bg-info"
  }.freeze

  def display_numero(numero, precision: nil)
    return "—" if numero.nil?

    options = { delimiter: ".", separator: ",", strip_insignificant_zeros: true }
    options[:precision] = precision unless precision.nil?
    number_with_precision(numero, **options)
  end

  def display_data(data)
    data.present? ? l(data.to_date, format: :default) : "—"
  end

  def display_mes_ano(data)
    data.present? ? l(data.to_date, format: "%b %Y") : "—"
  end

  def display_porcentagem(valor, cores: false, fracao: false)
    return "—" if valor.nil?

    numero = fracao ? valor * 100 : valor
    conteudo = number_to_percentage(numero, precision: 2, delimiter: ".", separator: ",", strip_insignificant_zeros: true)
    content_tag(:span, conteudo, class: classe_sinal(valor, cores:))
  end

  def display_moeda(valor, moeda: "BRL", cores: false, max_precision: false)
    return "—" if valor.nil?

    unidade = { "BRL" => "R$", "USD" => "US$", "EUR" => "€" }.fetch(moeda.to_s, moeda.to_s)
    conteudo = if max_precision
      variable_precision_currency(valor, unit: unidade)
    else
      number_to_currency(valor, precision: 2, unit: unidade, delimiter: ".", separator: ",")
    end
    content_tag(:span, conteudo, class: classe_sinal(valor, cores:))
  end

  def variable_precision_currency(valor, min_precision: 2, unit: "")
    numero = BigDecimal(valor.to_s)
    precisao = [(numero - numero.floor).to_s("F").sub(/0+\z/, "").split(".").last.to_s.length, min_precision].max
    number_to_currency(numero, precision: precisao, unit:, delimiter: ".", separator: ",")
  end

  def display_tipo(valor)
    return "—" if valor.blank?

    I18n.t("financeiro.tipos.#{valor}", default: valor.to_s.humanize)
  end

  def display_estado(valor)
    return "—" if valor.blank?

    I18n.t("financeiro.estados.#{valor}", default: valor.to_s.humanize)
  end

  def display_motivo(valor)
    I18n.t("financeiro.motivos.#{valor}", default: valor.to_s.humanize)
  end

  def sigla_instituicao(nome)
    palavra = nome.to_s.strip.split.first
    return "—" if palavra.blank?

    (palavra.length <= 3 ? palavra : palavra.first(2)).upcase
  end

  def status_badge(valor)
    content_tag(:span, display_estado(valor), class: "badge rounded-pill status-badge #{STATUS_CLASSES.fetch(valor.to_s, 'text-bg-light')}")
  end

  def registro_titulo(registro)
    return registro.nome if registro.respond_to?(:nome) && registro.nome.present?
    return registro.codigo if registro.respond_to?(:codigo) && registro.codigo.present?

    "#{registro.model_name.human} ##{registro.id}"
  end

  def registro_subtitulo(registro)
    return registro.descricao if registro.respond_to?(:descricao) && registro.descricao.present?
    return I18n.t("financeiro.tipos_ativo.#{registro.tipo}", default: registro.tipo.to_s.humanize) if registro.is_a?(Ativo) && registro.tipo.present?
    return registro.tipo.to_s.humanize if registro.respond_to?(:tipo) && registro.tipo.present?

    nil
  end

  def nav_link_class(path_or_prefix)
    ativo = path_or_prefix.is_a?(Regexp) ? request.path.match?(path_or_prefix) : current_page?(path_or_prefix)
    class_names("nav-link", active: ativo)
  end

  def formatar_atributo(nome, valor)
    return "—" if valor.nil? || valor == ""
    return display_data(valor) if nome.to_s.match?(/data|_at\z/) && valor.respond_to?(:to_date)
    return display_estado(valor) if nome.to_s == "estado"

    valor.to_s
  end

  def portfolio_chart(pontos, moeda: "BRL")
    serie = pontos.each_with_index.filter_map do |ponto, indice|
      valor = ponto[:patrimonio_final]
      { indice:, data: ponto[:data], valor: valor.to_f } if valor && ponto[:estado] == "calculado"
    end
    return if serie.size < 2

    largura = 760.0
    altura = 240.0
    margem = { esquerda: 18.0, direita: 18.0, topo: 18.0, base: 32.0 }
    valores = serie.pluck(:valor)
    minimo, maximo = valores.minmax
    amplitude = maximo - minimo
    amplitude = [maximo.abs * 0.1, 1.0].max if amplitude.zero?
    x = ->(indice) { margem[:esquerda] + indice.to_f / [pontos.size - 1, 1].max * (largura - margem[:esquerda] - margem[:direita]) }
    y = ->(valor) { margem[:topo] + (maximo - valor) / amplitude * (altura - margem[:topo] - margem[:base]) }
    segmentos = serie.chunk_while { |anterior, atual| atual[:indice] == anterior[:indice] + 1 }.to_a

    conteudo = []
    4.times do |indice|
      posicao = margem[:topo] + indice * (altura - margem[:topo] - margem[:base]) / 3
      conteudo << tag.line(x1: margem[:esquerda], y1: posicao, x2: largura - margem[:direita], y2: posicao, class: "grid")
    end
    segmentos.each do |segmento|
      coordenadas = segmento.map { |p| "#{x.call(p[:indice]).round(2)},#{y.call(p[:valor]).round(2)}" }.join(" ")
      conteudo << tag.polyline(points: coordenadas, class: "line")
    end
    serie.each do |ponto|
      conteudo << content_tag(:circle, content_tag(:title, "#{display_data(ponto[:data])}: #{strip_tags(display_moeda(ponto[:valor], moeda:))}"),
        cx: x.call(ponto[:indice]).round(2), cy: y.call(ponto[:valor]).round(2), r: 3.5, class: "point")
    end
    conteudo << tag.text(display_data(serie.first[:data]), x: margem[:esquerda], y: altura - 8)
    conteudo << tag.text(display_data(serie.last[:data]), x: largura - margem[:direita], y: altura - 8, text_anchor: "end")

    content_tag(:svg, safe_join(conteudo), viewBox: "0 0 #{largura.to_i} #{altura.to_i}", class: "portfolio-chart", role: "img",
      aria: { label: "Evolução do patrimônio entre #{display_data(serie.first[:data])} e #{display_data(serie.last[:data])}" })
  end

  private

  def classe_sinal(valor, cores:)
    return nil unless cores
    return "text-success" if valor.positive?
    return "text-danger" if valor.negative?
  end
end
