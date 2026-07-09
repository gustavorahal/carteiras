require "rufus-scheduler"

# Let's use the rufus-scheduler singleton
#
s = Rufus::Scheduler.singleton

# Do not schedule when Rails is run from its console, tests, or a Rake task.
return if defined?(Rails::Console) || Rails.env.test? || File.basename($PROGRAM_NAME) == "rake"


# Run every day at 1:30am
s.cron '30 1 * * *' do
  Rails.logger.info "Scheduler: Rodando CotacaoService.busca_e_registra_tudo em #{Time.current}"
  CotacaoService.busca_e_registra_tudo(Date.current)
  Rails.logger.flush
end
