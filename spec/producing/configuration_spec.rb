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
end
