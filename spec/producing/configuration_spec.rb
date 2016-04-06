require 'spec_helper'

describe Emque::Producing::Configuration do
  subject { Emque::Producing::Configuration.new }

  it "provides default values" do
    expect(subject.app_name).to eq ""
    expect(subject.error_handlers).to eq []
  end

  it "allows app_name to be overwritten" do
    subject.app_name = "my app"
    expect(subject.app_name).to eq "my app"
  end

  it "does not allow rabbitmq_options to be overwritten" do
    expect {
      subject.rabbitmq_options = {:requires_confirmation => false}
    }.to raise_error
  end

  describe "middleware" do
    it "does not allow direct assignment" do
      expect {
        subject.middleware = proc { |_| true }
      }.to raise_error
    end

    it "#use raises a ConfigurationError if the first arg is not callable" do
      expect {
        subject.use("not callable")
      }.to raise_error Emque::Producing::ConfigurationError
    end

    it "#use raises a ConfigurationError if the first arg's arity is not 1" do
      expect {
        subject.use(proc { true })
      }.to raise_error Emque::Producing::ConfigurationError

      expect {
        subject.use(proc { |_, _| true })
      }.to raise_error Emque::Producing::ConfigurationError
    end

    it "#use adds a valid callable object to the middleware stack" do
      expect(subject.middleware.count).to eq 0
      subject.use(proc { |_| true })
      expect(subject.middleware.count).to eq 1
    end
  end
end
