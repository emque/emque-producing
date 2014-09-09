require "spec_helper"
require "virtus"
require "emque/producing/message/message"

class TestMessage
  include Emque::Producing::Message

  topic "queue"
  message_type "queue.new"

  attribute :test_id, Integer, :required => true
  private_attribute :extra, String, :default => "value"
end

class MessageNoTopic
  include Emque::Producing::Message
  message_type "testing"
end

class MessageNoType
  include Emque::Producing::Message
  topic "testing"
end

describe Emque::Producing::Message do
  before do
    Emque::Producing.configure do |c|
      c.app_name = "apiv3"
    end
  end

  describe "#as_json" do
    it "creates the metadata" do
      message = TestMessage.new(:test_id => 1)
      metadata = message.add_metadata[:metadata]
      expect(metadata[:app]).to eql("apiv3")
    end

    it "can be transformed to json" do
      message = Oj.load(TestMessage.new().to_json)
      expect(message["metadata"]["app"]).to eql("apiv3")
    end
  end

  describe "#retry" do
    pending
  end

  it "validates the message for missing attributes" do
    message = TestMessage.new()
    expect(message).to_not be_valid
  end

  it "raises a useful message when trying to send an invalid message" do
    message = TestMessage.new()
    expected_error = Emque::Producing::Message::InvalidMessageError
    expect{message.publish(->{})}.to raise_error(expected_error)
  end

  it "validates that the message has a topic" do
    message = MessageNoTopic.new
    expected_error = Emque::Producing::Message::InvalidMessageError
    expect{message.publish(->{})}.to raise_error(expected_error, "A topic is required")
  end

  it "validates that the message has a message type" do
    message = MessageNoType.new
    expected_error = Emque::Producing::Message::InvalidMessageError
    expect{message.publish(->{})}.to raise_error(expected_error, "A message type is required")
  end

  it "applys a uuid per message" do
    message = TestMessage.new()
    expect(message.add_metadata[:metadata][:uuid]).to_not be_nil
  end

  it "has the sub type in the metadata" do
    message = TestMessage.new()
    expect(message.add_metadata[:metadata][:type]).to eql("queue.new")
  end
end
