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
      _remove_temporarios(conta_corrente)
    end

    # remova entradas de extrato temporárias, se presente
    def self._remove_temporarios(conta_corrente)
      conta_corrente.extratos.where(temporario: true).delete_all
    end
  end
end
