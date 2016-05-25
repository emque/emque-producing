require "spec_helper"
require "virtus"
require "emque/producing/message/message"
require "emque/producing/publisher/rabbitmq"

class TestMessageRaiseOnFailureFalse
  include Emque::Producing.message

  topic "queue"
  message_type "queue.new"

  raise_on_failure false
end

class TestMessageRaiseOnFailureTrue
  include Emque::Producing.message

  topic "queue"
  message_type "queue.new"

  raise_on_failure true
end

describe "connection pools" do
  it "should use separate pools for confirm messages" do
    Emque::Producing::Publisher::RabbitMq::CHANNEL_POOL = Queue.new
    Emque::Producing::Publisher::RabbitMq::CONFIRM_CHANNEL_POOL = Queue.new
    publisher = Emque::Producing::Publisher::RabbitMq.new
    message = TestMessageRaiseOnFailureFalse.new

    expect(Emque::Producing::Publisher::RabbitMq::CHANNEL_POOL.size).to be(0)
    expect(Emque::Producing::Publisher::RabbitMq::CONFIRM_CHANNEL_POOL.size).to be(0)

    publisher.publish(message.topic, message.message_type, "test", nil, message.raise_on_failure?)

    expect(Emque::Producing::Publisher::RabbitMq::CHANNEL_POOL.size).to be(1)
    expect(Emque::Producing::Publisher::RabbitMq::CONFIRM_CHANNEL_POOL.size).to be(0)
  end

  it "should use separate pools for non-confirm messages" do
    Emque::Producing::Publisher::RabbitMq::CHANNEL_POOL = Queue.new
    Emque::Producing::Publisher::RabbitMq::CONFIRM_CHANNEL_POOL = Queue.new
    publisher = Emque::Producing::Publisher::RabbitMq.new
    message = TestMessageRaiseOnFailureTrue.new

    expect(Emque::Producing::Publisher::RabbitMq::CHANNEL_POOL.size).to be(0)
    expect(Emque::Producing::Publisher::RabbitMq::CONFIRM_CHANNEL_POOL.size).to be(0)

    publisher.publish(message.topic, message.message_type, "test", nil, message.raise_on_failure?)

    expect(Emque::Producing::Publisher::RabbitMq::CHANNEL_POOL.size).to be(0)
    expect(Emque::Producing::Publisher::RabbitMq::CONFIRM_CHANNEL_POOL.size).to be(1)
  end
end
