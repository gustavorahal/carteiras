module Normalizavel
  extend ActiveSupport::Concern

  class_methods do
    def normaliza_texto(*campos, maiusculo: false)
      before_validation do
        campos.each do |campo|
          valor = public_send(campo)
          next unless valor.is_a?(String)

          valor = valor.strip
          valor = valor.upcase if maiusculo
          public_send("#{campo}=", valor.presence)
        end
      end
    end
  end
end
