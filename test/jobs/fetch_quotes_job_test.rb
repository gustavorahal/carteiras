require 'test_helper'

class FetchQuotesJobTest < ActiveJob::TestCase
  test 'fetches and registers quotes for the given date' do
    data = Date.new(2026, 7, 9)

    CotacaoService.stub(:busca_e_registra_tudo, ->(received_data) { @received_data = received_data }) do
      FetchQuotesJob.perform_now(data)
    end

    assert_equal data, @received_data
  end
end
