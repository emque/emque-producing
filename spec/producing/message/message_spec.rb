require "spec_helper"
require "virtus"
require "emque/producing/message/message"
require "emque/producing/message/message_with_changeset"

class TestMessageWithChangesetCustomBuildId
  include Emque::Producing.message(:with_changeset => true)

  topic "queue"
  message_type "queue.new"

  attribute :test_uuid, Integer, :required => true, :default => :build_id
  private_attribute :extra, String, :default => "value"

  def build_id
    if updated
      updated.fetch("uuid") { updated[:uuid] }
    elsif original
      original.fetch("uuid") { original[:uuid] }
    else
      raise Emque::Producing::Message::InvalidMessageError
    end
  end
end

class TestMessage
  include Emque::Producing.message

  topic "queue"
  message_type "queue.new"

  attribute :test_id, Integer, :required => true
  private_attribute :extra, String, :default => "value"
end

class MessageNoTopic
  include Emque::Producing.message
  message_type "testing"
end

class MessageNoType
  include Emque::Producing.message
  topic "testing"
end

class TestMessageWithChangeset
  include Emque::Producing.message(:with_changeset => true)

  topic "queue"
  message_type "queue.new"

  attribute :test_id, Integer, :required => true, :default => :build_id
  private_attribute :extra, String, :default => "value"
  translate_changeset_attrs(
    :type => :event_type, :date => :event_date, :not_an_attr => :still_not_an_attr
  )
end

class TestMessageDontRaiseOnFailure
  include Emque::Producing.message

  IgnoreThisError = Class.new(StandardError)
  DontIgnoreThisError = Class.new(StandardError)

  topic "queue"
  message_type "queue.new"

  ignored_exceptions IgnoreThisError

  raise_on_failure false
end

class TestPublisher
  InvalidMessageError = Class.new(StandardError)
  TimeoutMessageError = Class.new(StandardError)

  Emque::Producing.configure do |c|
    c.ignored_exceptions = c.ignored_exceptions + [InvalidMessageError, TimeoutMessageError]
  end

  def publish(topic, message_type, message, key = nil)
  end
end

describe Emque::Producing::Message do
  before { Emque::Producing.configure { |c| c.app_name = "my_app" } }

  describe "translating changeset attr names" do
    it "allows a client to change attr names in the changeset message" do
      produced_message = TestMessageWithChangeset.new(
        :test_id => 1,
        :original => {"type" => "Game", "date" => "2000-01-02"},
        :updated => {"type" => "Event", "date" => "2000-01-01"}
      )
      json = produced_message.to_json
      consumed_message = Oj.load(json)
      expect(consumed_message["change_set"]).to eql(
        {
          "original"=>{"event_type"=>"Game", "event_date"=>"2000-01-02"},
          "updated"=>{"event_type"=>"Event", "event_date"=>"2000-01-01"},
          "delta"=>{
            "event_type"=>{
              "original"=>"Game", "updated"=>"Event"
            },
            "event_date"=>{
              "original"=>"2000-01-02", "updated"=>"2000-01-01"
            }
          }
        }
      )
    end

    it "does not add new attr if the old attr is not present" do
      produced_message = TestMessageWithChangeset.new(
        :test_id => 1,
        :updated => {"type" => "Event"},
        :original => {"type" => "Game"}
      )
      json = produced_message.to_json
      consumed_message = Oj.load(json)
      expect(consumed_message["change_set"]).to eql(
        {
          "original"=>{"event_type"=>"Game"},
          "updated"=>{"event_type"=>"Event"},
          "delta"=>{
            "event_type"=>{
              "original"=>"Game", "updated"=>"Event"
            }
          }
        }
      )
    end
  end

  describe "#to_json" do
    it "creates the metadata" do
      message = TestMessage.new(:test_id => 1)
      metadata = message.add_metadata[:metadata]
      expect(metadata[:app]).to eql("my_app")
    end

    it "can be transformed to json" do
      message = Oj.load(TestMessage.new().to_json)
      expect(message["metadata"]["app"]).to eql("my_app")
    end

    it "includes valid attributes in json" do
      produced_message = TestMessage.new(:test_id => 1)
      json = produced_message.to_json
      consumed_message = Oj.load(json)
      expect(consumed_message["test_id"]).to eql(1)
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

  context "message with changeset" do
    describe "custom #build_id behavior" do
      it "raises an InvalidMessageError when no updated or original object is passed in" do
        expect{TestMessageWithChangesetCustomBuildId.new(:not_the_id => 1)}.to raise_error(
          Emque::Producing::Message::InvalidMessageError
        )
      end

      it "defaults to the id of the original object if not passed an updated object" do
        produced_message = TestMessageWithChangesetCustomBuildId.new(
          :original => {:uuid => 3, :attr => "old_value"}
        )
        json = produced_message.to_json
        consumed_message = Oj.load(json)
        expect(consumed_message["test_uuid"]).to eql(3)
      end

      it "defaults to the id of the updated object if passed an id" do
        produced_message = TestMessageWithChangesetCustomBuildId.new(
          :original => {:uuid => 1, :attr => "old_value"},
          :updated => {:uuid => 2, :attr => "new_value"}
        )
        json = produced_message.to_json
        consumed_message = Oj.load(json)
        expect(consumed_message["test_uuid"]).to eql(2)
      end
    end

    describe "default #build_id behavior" do
      it "raises an InvalidMessageError when no updated or original object is passed in" do
        expect{TestMessageWithChangeset.new(:not_the_id => 1)}.to raise_error(
          Emque::Producing::Message::InvalidMessageError
        )
      end

      it "defaults to the id of the original object if not passed an updated object" do
        produced_message = TestMessageWithChangeset.new(
          :original => {:id => 3, :attr => "old_value"}
        )
        json = produced_message.to_json
        consumed_message = Oj.load(json)
        expect(consumed_message["test_id"]).to eql(3)
      end

      it "defaults to the id of the updated object if passed an id" do
        produced_message = TestMessageWithChangeset.new(
          :original => {:id => 1, :attr => "old_value"},
          :updated => {:id => 2, :attr => "new_value"}
        )
        json = produced_message.to_json
        consumed_message = Oj.load(json)
        expect(consumed_message["test_id"]).to eql(2)
      end
    end

    it "defaults to a changeset of 'created' when no updated or original is passed in" do
      produced_message = TestMessageWithChangeset.new(:test_id => 1)
      json = produced_message.to_json
      consumed_message = Oj.load(json)
      expect(consumed_message["change_set"]).to eql(
        {"original"=>{}, "updated"=>{}, "delta"=>"_created"}
      )
    end

    it "indicates a deleted object when the update is not passed in" do
      produced_message = TestMessageWithChangeset.new(
        :test_id => 1,
        :original => {:attr => "old_value"}
      )
      json = produced_message.to_json
      consumed_message = Oj.load(json)
      expect(consumed_message["change_set"]).to eql(
        {"original"=>{"attr"=>"old_value"}, "updated"=>{}, "delta"=>"_deleted"}
      )
    end

    it "returns a changeset when update and original values are passed in" do
      produced_message = TestMessageWithChangeset.new(
        :test_id => 1,
        :updated => {:attr => "new_value"},
        :original => {:attr => "old_value"}
      )
      json = produced_message.to_json
      consumed_message = Oj.load(json)
      expect(consumed_message["change_set"]).to eql(
        {
          "original"=>{"attr"=>"old_value"},
          "updated"=>{"attr"=>"new_value"},
          "delta"=>{
            "attr"=>{
              "original"=>"old_value", "updated"=>"new_value"
            }
          }
        }
      )
    end
  end

  context "valid?" do
    describe "it returns true" do
      it "returns true when the message is valid" do
        message = TestMessage.new(:test_id => 1)
        expect(message.valid?).to be(true)
      end

      it "returns fales when the message is invalid" do
        message = TestMessage.new()
        expect(message.valid?).to be(false)
      end
    end
  end

  describe "raise_on_failure" do
    context "when false" do
      it "sets raise_on_failure to false" do
        message = TestMessageDontRaiseOnFailure.new
        expect(message.raise_on_failure?).to be(false)
      end

      it "rescues exceptions from publish" do
        message = TestMessageDontRaiseOnFailure.new
        publisher = TestPublisher.new
        allow(Emque::Producing).to receive(:publishers) { {:test => publisher} }
        allow(publisher).to receive(:publish).and_raise(TestPublisher::InvalidMessageError)

        expect{message.publish([:test])}.not_to raise_error
      end

      it "rescues exceptions when publish doesn't send" do
        message = TestMessageDontRaiseOnFailure.new
        publisher = TestPublisher.new
        allow(Emque::Producing).to receive(:publishers) { {:test => publisher} }
        allow(publisher).to receive(:publish) { false }

        expect{message.publish([:test])}.not_to raise_error
      end

      it "rescues exceptions that are in the ignored list of excpetions" do
        message = TestMessageDontRaiseOnFailure.new
        publisher = TestPublisher.new
        allow(Emque::Producing).to receive(:publishers) { {:test => publisher} }
        allow(publisher).to receive(:publish).and_raise(TestMessageDontRaiseOnFailure::IgnoreThisError)

        expect{message.publish([:test])}.not_to raise_error
      end

      it "doesnt catch an exceptions that isn't in the " do
        message = TestMessageDontRaiseOnFailure.new
        publisher = TestPublisher.new
        allow(Emque::Producing).to receive(:publishers) { {:test => publisher} }
        allow(publisher).to receive(:publish).and_raise(TestMessageDontRaiseOnFailure::DontIgnoreThisError)

        expect{message.publish([:test])}.to raise_error(TestMessageDontRaiseOnFailure::DontIgnoreThisError)
      end
    end

    context "when true" do
      it "sets raise_on_failure to true" do
        message = TestMessage.new(:test_id => 1)
        expect(message.raise_on_failure?).to be(true)
      end

      it "raises exceptions from publisher" do
        message = TestMessage.new(:test_id => 1)
        publisher = TestPublisher.new
        allow(Emque::Producing).to receive(:publishers) { {:test => publisher} }
        allow(publisher).to receive(:publish).and_raise(TestPublisher::InvalidMessageError)

        expect{message.publish([:test])}.to raise_error(TestPublisher::InvalidMessageError)
      end

      it "raises exceptions when publish doesn't send" do
        message = TestMessage.new(:test_id => 1)
        publisher = TestPublisher.new
        allow(Emque::Producing).to receive(:publishers) { {:test => publisher} }
        allow(publisher).to receive(:publish) { false }

        expect{message.publish([:test])}.to raise_error(Emque::Producing::Message::MessagesNotSentError)
      end
    end
  end
end
