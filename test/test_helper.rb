ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'minitest/mock'

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  #parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...

  def file_path(name)
    Rails.root.to_s + "/test/fixtures/files/#{name}"
  end

  def with_env(vars)
    old_values = vars.keys.index_with { |key| ENV[key] }

    vars.each do |key, value|
      value.nil? ? ENV.delete(key) : ENV[key] = value
    end

    yield
  ensure
    old_values&.each do |key, value|
      value.nil? ? ENV.delete(key) : ENV[key] = value
    end
  end

  # Source: https://github.com/varvet/pundit/issues/204
  def assert_permit(user, record, action)
    msg = "User #{user.inspect} should be permitted to #{action} #{record}, but isn't permitted"
    assert permit(user, record, action), msg
  end

  def refute_permit(user, record, action)
    msg = "User #{user.inspect} should NOT be permitted to #{action} #{record}, but is permitted"
    refute permit(user, record, action), msg
  end

  def permit(user, record, action)
    cls = self.class.to_s.gsub(/Test/, '')
    cls.constantize.new(user, record).public_send("#{action.to_s}?")
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
