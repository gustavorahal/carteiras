module Extratos
  class Importa

  def self.importar(conta_corrente, file_path)
    case conta_corrente.corretora.nome
    when 'XP'
      ImportaXp.importar(conta_corrente, file_path)
    when 'Avenue'
      ImportaAvenue.importar(conta_corrente, file_path)
    when 'Vitreo'
      ImportaVitreo.importar(conta_corrente, file_path)
    else
      raise StandardError, 'Corretora não suportada'
    end
  end
  end
end
