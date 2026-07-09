require 'test_helper'

class UtilsTest < ActiveSupport::TestCase
  FakeRapidapiResponse = Struct.new(:code, :message, :body)

  FakeRapidapiHttp = Struct.new(:response) do
    attr_reader :use_ssl, :open_timeout, :read_timeout, :captured_request

    def use_ssl=(value)
      @use_ssl = value
    end

    def open_timeout=(value)
      @open_timeout = value
    end

    def read_timeout=(value)
      @read_timeout = value
    end

    def request(request)
      @captured_request = request
      response
    end
  end

  test "ultimo dia util: se hoje segunda, retorna sexta" do
    travel_to Date.new(2021, 4, 19)
    data_teste = Date.today
    data_esperada = Date.new(2021, 4, 16)
    data_retornada = Utils.ultimo_dia_util(data_teste)
    assert_equal data_esperada, data_retornada
  end

  test "ultimo dia util: se data no passado dia util, retorna ela mesma" do
    travel_to Date.new(2021, 4, 16)
    data_teste = Date.new(2021, 4, 14)
    data_esperada = Date.new(2021, 4, 14)
    data_retornada = Utils.ultimo_dia_util(data_teste)
    assert_equal data_esperada, data_retornada
  end

  test "ultimo dia util: se data no passado final de semana, retorna dia util anterior" do
    travel_to Date.new(2021, 4, 18) # domingo "hoje"
    data_teste = Date.new(2021, 4, 11) # domingo anterior
    data_esperada = Date.new(2021, 4, 9) # sexta
    data_retornada = Utils.ultimo_dia_util(data_teste)
    assert_equal data_esperada, data_retornada
  end

  test "ultimo dia util: se hoje final de semana, retorna dia util anterior" do
    travel_to Date.new(2021, 4, 18) # domingo
    data_teste = Date.today
    data_esperada = Date.new(2021, 4, 16) # sexta
    data_retornada = Utils.ultimo_dia_util(data_teste)
    assert_equal data_esperada, data_retornada
  end

  test "ultimo dia util: se hoje feriado, retorna ultimo dia util" do
    travel_to Date.new(2020, 5, 1) # dia do trabalho, uma sexta-feira
    data_teste = Date.today
    data_esperada = Date.new(2020, 4, 30) # quinta
    data_retornada = Utils.ultimo_dia_util(data_teste)
    assert_equal data_esperada, data_retornada
  end

  test "fetch_rapidapi_json usa TLS padrão, timeouts e headers" do
    response = FakeRapidapiResponse.new('200', 'OK', { ok: true }.to_json)
    http = FakeRapidapiHttp.new(response)

    Net::HTTP.stub(:new, http) do
      with_env("RAPIDAPI_KEY" => "secret-key") do
        result = Utils.fetch_rapidapi_json("https://example.test/resource", "rapidapi.example.test")

        assert_equal({ "ok" => true }, result)
      end
    end

    assert_equal true, http.use_ssl
    assert_equal 5, http.open_timeout
    assert_equal 10, http.read_timeout
    assert_equal "rapidapi.example.test", http.captured_request["x-rapidapi-host"]
    assert_equal "secret-key", http.captured_request["x-rapidapi-key"]
  end

  test "fetch_rapidapi_json falha em resposta http sem sucesso" do
    response = FakeRapidapiResponse.new('503', 'Service Unavailable', "")
    http = FakeRapidapiHttp.new(response)

    Net::HTTP.stub(:new, http) do
      with_env("RAPIDAPI_KEY" => "secret-key") do
        error = assert_raises(StandardError) do
          Utils.fetch_rapidapi_json("https://example.test/resource", "rapidapi.example.test")
        end

        assert_equal "RapidAPI request failed with HTTP 503: Service Unavailable", error.message
      end
    end
  end

end
