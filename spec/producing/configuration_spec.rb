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

  it "rabbitmq mandatory_messages default is true" do
    expect(subject.rabbitmq_options[:mandatory_messages]).to eq true
  end

  it "rabbitmq confirm_messages default is true" do
    expect(subject.rabbitmq_options[:confirm_messages]).to eq true
  end
end
