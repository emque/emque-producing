require 'spec_helper'

describe Emque::Producing::Configuration do
  subject { Emque::Producing::Configuration.new }

  it "provides default values" do
    expect(subject.app_name).to eq ""
    expect(subject.error_handlers).to eq []
    expect(subject.kafka_seed_brokers).to eq ["localhost:9092"]
  end

  it "allows app_name to be overwritten" do
    subject.app_name = "my app"
    expect(subject.app_name).to eq "my app"
  end

  it "allows seed_brokers to be overwritten" do
    subject.kafka_seed_brokers = ["kafka1:9092", "kafka2:9092"]
    expect(subject.kafka_seed_brokers).to eq ["kafka1:9092", "kafka2:9092"]
  end
end
