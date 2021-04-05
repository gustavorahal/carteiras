require 'rufus-scheduler'

# Let's use the rufus-scheduler singleton
#
s = Rufus::Scheduler.singleton

# do not schedule when Rails is run from its console, for a test/spec, or from a Rake task
return if defined?(Rails::Console) || Rails.env.test? || File.split($0).last == 'rake'


# Run every day at 1:30am
s.cron '30 1 * * *' do
  Rails.logger.info "Scheduler: Rodando CotacaoService.busca_e_registra_tudo em #{Time.now}"
  CotacaoService.busca_e_registra_tudo(Date.today)
  Rails.logger.flush
end
