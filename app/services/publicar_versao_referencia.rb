class PublicarVersaoReferencia
  def self.call(versao)
    VersaoReferencia.transaction do
      versao.referencia.lock!
      versao.lock!
      raise ArgumentError, "Somente rascunhos podem ser publicados" unless versao.rascunho?
      alocacoes = versao.alocacoes.lock.load
      total = alocacoes.sum(&:percentual)
      raise ArgumentError, "A referência deve possuir ao menos uma alocação" if alocacoes.empty?
      raise ArgumentError, "A soma das alocações deve ser exatamente 100%" unless total == 100.to_d

      versao.referencia.versoes.publicadas.where.not(id: versao.id)
        .where(vigencia_inicial: ..versao.vigencia_inicial).update_all(estado: "encerrada", updated_at: Time.current)
      versao.update!(estado: :publicada)
      versao
    end
  end
end
