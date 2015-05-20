$TESTING = true

require "simplecov"
SimpleCov.start do
  add_filter "spec/"
end

require "pry"
require "emque-producing"

ENV["EMQUE_ENV"] = "test"

module VerifyAndResetHelpers
  def verify(object)
    RSpec::Mocks.proxy_for(object).verify
  end

  def reset(object)
    RSpec::Mocks.proxy_for(object).reset
  end
end

RSpec.configure do |config|
  config.order = "random"

  config.include VerifyAndResetHelpers
end
